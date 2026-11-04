local test = require("test")
local json = require("json")
local registry = require("registry")
local llm = require("llm")
local prompt = require("prompt")
local providers = require("providers")
local claude_mapper = require("claude_mapper")
local claude_client = require("claude_client")
local claude_generate = require("claude_generate")
local claude_structured = require("claude_structured")
local bedrock_mapper = require("bedrock_mapper")
local bedrock_client = require("bedrock_client")
local bedrock_generate = require("bedrock_generate")
local bedrock_structured = require("bedrock_structured")
local openai_mapper = require("openai_mapper")
local openai_generate = require("openai_generate")
local openai_structured = require("openai_structured")
local compat_mapper = require("compat_mapper")
local compat_generate = require("compat_generate")
local compat_structured = require("compat_structured")
local google_mapper = require("google_mapper")
local google_generate = require("google_generate")
local google_structured = require("google_structured")

local BINDING_BETA = "thinking-binding-controls-2026-08-01"
local SCHEMA = { type = "object", properties = { a = { type = "number" } }, required = { "a" }, additionalProperties = false }

local function text(value) return { { type = "text", text = value } } end
local function signed(name) return { type = "thinking", thinking = "", signature = name } end

local CLAUDE_REPLY = { content = { { type = "text", text = "{\"a\":1}" },
    { type = "tool_use", name = "structured_output", id = "s", input = { a = 1 } } },
    stop_reason = "end_turn", usage = { input_tokens = 1, output_tokens = 1 } }
local BEDROCK_REPLY = { output = { message = { role = "assistant", content = { { text = "ok" },
    { toolUse = { toolUseId = "s", name = "structured_output", input = { a = 1 } } } } } },
    stopReason = "end_turn", usage = { inputTokens = 1, outputTokens = 1 } }

local function capture_claude(handler): any
    local sent: any = {}
    handler._client = { ENDPOINTS = { MESSAGES = "/messages" }, request = function(_, payload, options)
        table.insert(sent, { payload = payload, betas = options and options.beta_features })
        return json.decode((json.encode(CLAUDE_REPLY)))
    end }
    return sent
end

local function capture_bedrock(handler): any
    local sent: any = {}
    handler._client = { converse = function(_, payload)
        table.insert(sent, { payload = payload })
        return json.decode((json.encode(BEDROCK_REPLY)))
    end }
    return sent
end

local function capture_google(handler): any
    local sent: any = {}
    local client_contract = { with_context = function(self) return self end,
        open = function(self) return self end,
        request = function(_, args)
            table.insert(sent, { payload = args.payload or args })
            return { candidates = { { content = { parts = { { text = "{\"a\":1}" } } }, finishReason = "STOP" } },
                usageMetadata = { promptTokenCount = 1, candidatesTokenCount = 1 } }
        end }
    handler._contract = { get = function() return client_contract end }
    handler._ctx = { all = function() return {} end, get = function() return "client" end }
    return sent
end

local function capture_openai(handler): any
    local sent: any = {}
    handler._client = { ENDPOINTS = { RESPONSES = "/responses", CHAT_COMPLETIONS = "/chat/completions" },
        request = function(_, payload)
            table.insert(sent, { payload = payload })
            return { status = "completed", output = { { type = "message", content = { { type = "output_text", text = "{\"a\":1}" } } } },
                choices = { { message = { role = "assistant", content = "{\"a\":1}" }, finish_reason = "stop" } },
                usage = { input_tokens = 1, output_tokens = 1, prompt_tokens = 1, completion_tokens = 1 }, metadata = {} }
        end }
    return sent
end

-- Wire order of an assistant turn as signatures, call ids and text.
local function claude_order(message)
    local order = {}
    for _, part in ipairs(message.content) do
        table.insert(order, part.signature or part.id or part.text or part.type)
    end
    return order
end

local function bedrock_order(message)
    local order = {}
    for _, part in ipairs(message.content) do
        local reasoning = part.reasoningContent and part.reasoningContent.reasoningText
        table.insert(order, reasoning and reasoning.signature or (part.toolUse and part.toolUse.toolUseId)
            or part.text or (part.cachePoint and "cachePoint") or "other")
    end
    return order
end

local function assert_order(actual, expected)
    test.eq(table.concat(actual, "|"), table.concat(expected, "|"))
end

local RESPONSE_ORDER = { "s1", "before ", "s2", "c1", "s3", "c2", "after" }

local CLAUDE_RESPONSE = {
    { type = "thinking", thinking = "", signature = "s1" },
    { type = "text", text = "before " },
    { type = "thinking", thinking = "", signature = "s2" },
    { type = "tool_use", id = "c1", name = "t", input = { a = 1 } },
    { type = "thinking", thinking = "", signature = "s3" },
    { type = "tool_use", id = "c2", name = "t", input = { a = 2 } },
    { type = "text", text = "after" },
}

local function reasoning_block(name) return { reasoningContent = { reasoningText = { text = "", signature = name } } } end

local BEDROCK_RESPONSE = {
    reasoning_block("s1"),
    { text = "before " },
    reasoning_block("s2"),
    { toolUse = { toolUseId = "c1", name = "t", input = { a = 1 } } },
    reasoning_block("s3"),
    { toolUse = { toolUseId = "c2", name = "t", input = { a = 2 } } },
    { text = "after" },
}

local function sse_stream(events)
    local body = ""
    for _, event in ipairs(events) do
        body = body .. "event: " .. event[1] .. "\ndata: " .. json.encode(event[2]) .. "\n\n"
    end
    local done = false
    return { stream = { read = function()
        if done then return nil end
        done = true
        return body
    end }, metadata = {} }
end

local function claude_stream_events(response)
    local events = { { "message_start", { message = { usage = { input_tokens = 1 } } } } }
    for index, block in ipairs(response) do
        local at = index - 1
        if block.type == "thinking" then
            table.insert(events, { "content_block_start", { index = at, content_block = { type = "thinking", thinking = "", signature = "" } } })
            table.insert(events, { "content_block_delta", { index = at, delta = { type = "signature_delta", signature = block.signature } } })
        elseif block.type == "text" then
            table.insert(events, { "content_block_start", { index = at, content_block = { type = "text", text = "" } } })
            table.insert(events, { "content_block_delta", { index = at, delta = { type = "text_delta", text = block.text } } })
        else
            table.insert(events, { "content_block_start", { index = at, content_block = { type = "tool_use", id = block.id, name = block.name } } })
            table.insert(events, { "content_block_delta", { index = at, delta = { type = "input_json_delta", partial_json = json.encode(block.input) } } })
        end
        table.insert(events, { "content_block_stop", { index = at } })
    end
    table.insert(events, { "message_delta", { delta = { stop_reason = "tool_use" }, usage = { output_tokens = 2 } } })
    table.insert(events, { "message_stop", {} })
    return events
end

local function eventstream_message(event_type, body)
    local function header(name, value)
        return string.char(#name) .. name .. string.char(7) .. string.pack(">I2", #value) .. value
    end
    local headers = header(":event-type", event_type) .. header(":content-type", "application/json")
        .. header(":message-type", "event")
    local payload = json.encode(body)
    local total = 12 + #headers + #payload + 4
    return string.pack(">I4I4I4", total, #headers, 0) .. headers .. payload .. string.pack(">I4", 0)
end

local function bedrock_stream(response)
    local chunks = { eventstream_message("messageStart", { role = "assistant" }) }
    local function add(name, body) table.insert(chunks, eventstream_message(name, body)) end
    for index, block in ipairs(response) do
        local at = index - 1
        if block.reasoningContent then
            add("contentBlockDelta", { contentBlockIndex = at, delta = { reasoningContent = {
                signature = block.reasoningContent.reasoningText.signature } } })
        elseif block.text then
            add("contentBlockDelta", { contentBlockIndex = at, delta = { text = block.text } })
        else
            add("contentBlockStart", { contentBlockIndex = at, start = { toolUse = { toolUseId = block.toolUse.toolUseId, name = "t" } } })
            add("contentBlockDelta", { contentBlockIndex = at, delta = { toolUse = { input = json.encode(block.toolUse.input) } } })
        end
        add("contentBlockStop", { contentBlockIndex = at })
    end
    add("messageStop", { stopReason = "tool_use" })
    add("metadata", { usage = { inputTokens = 1, outputTokens = 2 } })
    local at = 0
    return { stream = { read = function()
        at = at + 1
        return chunks[at]
    end }, metadata = {} }
end

-- The rows a host persists from one tool-using response.
local function stored_rows(result): any
    local metadata = {
        thinking_blocks = result.metadata.thinking_blocks,
        content_positions = result.metadata.content_positions,
    }
    local rows = {
        { role = "user", content = text("q") },
        { role = "assistant", content = text(result.result.content), metadata = metadata },
    }
    for _, call in ipairs(result.result.tool_calls) do
        table.insert(rows, { role = "function_call", content = {},
            function_call = { id = call.id, name = call.name, arguments = call.arguments } })
    end
    for _, call in ipairs(result.result.tool_calls) do
        table.insert(rows, { role = "function_result", name = call.name, function_call_id = call.id, content = text("r") })
    end
    return rows
end

local function claude_replay(rows, options)
    local sent = capture_claude(claude_generate)
    local _, err = claude_generate.handler({ model = "m", messages = rows, options = options or { max_tokens = 100 } })
    test.is_nil(err)
    return sent[1].payload, sent[1].betas
end

local function bedrock_replay(rows, options)
    local sent = capture_bedrock(bedrock_generate)
    local _, err = bedrock_generate.handler({ model = "m", messages = rows, options = options or { max_tokens = 100 } })
    test.is_nil(err)
    return sent[1].payload
end

local function claude_replay_order(result)
    return claude_order(claude_replay(stored_rows(result)).messages[2])
end

local function bedrock_replay_order(result)
    return bedrock_order(bedrock_replay(stored_rows(result)).messages[2])
end

local function has_block(list, predicate)
    for _, message in ipairs(list) do
        if type(message.content) == "table" then
            for _, part in ipairs(message.content) do
                if predicate(part) then return true end
            end
        end
    end
    return false
end

local function stale_rows(): any
    return {
        { role = "user", content = text("q") },
        { role = "assistant", content = text("handing off"), metadata = {
            thinking_blocks = { signed("s1") }, stale_thinking = true } },
        { role = "function_call", content = {}, function_call = { id = "c1", name = "handoff", arguments = {} } },
        { role = "function_result", name = "handoff", function_call_id = "c1", content = text("ok") },
    }
end

local function is_claude_thinking(part) return part.type == "thinking" end
local function is_bedrock_reasoning(part) return part.reasoningContent ~= nil end

local function policy_providers(handler, method, policy)
    return {
        driver_declares_legacy_reasoning_flag = function() return false end,
        driver_output_policy = function() return policy, nil end,
        open = function()
            return { [method] = function(_, args) return handler.handler(args) end }
        end,
    }
end

local function use_card(card)
    llm._models = { get_by_name = function() return card, nil end, get_by_class = function() return {}, nil end }
end

local BUDGET_POLICY = { thinking = "budget", default_max_tokens = 2000 }

-- A response as the wire blocks of each driver, from { "s1", "text", { "c1" } } shorthand.
local function claude_blocks(shape)
    local blocks = {}
    for _, item in ipairs(shape) do
        if type(item) == "table" then
            table.insert(blocks, { type = "tool_use", id = item[1], name = "t", input = { a = 1 } })
        elseif item:match("^s%d$") then
            table.insert(blocks, { type = "thinking", thinking = "", signature = item })
        else
            table.insert(blocks, { type = "text", text = item })
        end
    end
    return blocks
end

local function bedrock_blocks(shape)
    local blocks = {}
    for _, item in ipairs(shape) do
        if type(item) == "table" then
            table.insert(blocks, { toolUse = { toolUseId = item[1], name = "t", input = { a = 1 } } })
        elseif item:match("^s%d$") then
            table.insert(blocks, reasoning_block(item))
        else
            table.insert(blocks, { text = item })
        end
    end
    return blocks
end

-- The four extraction paths, each returning a response as llm hands it to a host.
local EXTRACTION_PATHS = {
    { name = "Claude JSON", replay = claude_replay, order = claude_order, extract = function(shape)
        return claude_mapper.format_success_response({ content = claude_blocks(shape), stop_reason = "tool_use",
            usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
    end },
    { name = "Claude stream", replay = claude_replay, order = claude_order, extract = function(shape)
        local _, _, stream = claude_client.process_stream(sse_stream(claude_stream_events(claude_blocks(shape))), {})
        return claude_mapper.format_streaming_response(stream, {}, stream.usage, stream.finish_reason, stream.metadata)
    end },
    { name = "Bedrock JSON", replay = bedrock_replay, order = bedrock_order, extract = function(shape)
        return bedrock_mapper.format_success_response({ output = { message = { role = "assistant", content = bedrock_blocks(shape) } },
            stopReason = "tool_use", usage = { inputTokens = 1, outputTokens = 1 } }, {})
    end },
    { name = "Bedrock stream", replay = bedrock_replay, order = bedrock_order, extract = function(shape)
        local _, _, stream = bedrock_client.process_converse_stream(bedrock_stream(bedrock_blocks(shape)), {})
        return bedrock_mapper.format_streaming_response(stream, {}, stream.usage, stream.finish_reason, stream.metadata)
    end },
}

local function define_tests()
    describe("Replay safety", function()
        after_each(function()
            llm._providers = nil
            llm._models = nil
            llm._usage_tracker = nil
        end)

        describe("stale blocks without a bindable thinking object", function()
            local UNBINDABLE = {
                { name = "default budget at effort 0", accepts = nil, options = { max_tokens = 100 } },
                { name = "adaptive at effort 0", accepts = { thinking = "adaptive" }, options = { max_tokens = 100, thinking_effort = 0 } },
                { name = "none", accepts = { thinking = "none" }, options = { max_tokens = 100 } },
            }
            for _, case in ipairs(UNBINDABLE) do
                it("removes marked blocks on Claude: " .. case.name, function()
                    local sent = capture_claude(claude_generate)
                    assert(claude_generate.handler({ model = "m", messages = stale_rows(), options = case.options, accepts = case.accepts }))
                    test.is_false(has_block(sent[1].payload.messages, is_claude_thinking))
                    test.is_nil(sent[1].betas)
                    assert_order(claude_order(sent[1].payload.messages[2]), { "handing off", "c1" })
                end)
                it("removes marked blocks on Bedrock: " .. case.name, function()
                    local sent = capture_bedrock(bedrock_generate)
                    assert(bedrock_generate.handler({ model = "m", messages = stale_rows(), options = case.options, accepts = case.accepts }))
                    test.is_false(has_block(sent[1].payload.messages, is_bedrock_reasoning))
                    assert_order(bedrock_order(sent[1].payload.messages[2]), { "handing off", "c1" })
                end)
            end

            it("removes marked blocks on Claude between_tools", function()
                local sent = capture_claude(claude_generate)
                assert(claude_generate.handler({ model = "m", messages = stale_rows(), options = {
                    max_tokens = 100, thinking_effort = 50, request = { thinking = { type = "between_tools" } } },
                    accepts = { thinking = "adaptive" } }))
                test.eq(sent[1].payload.thinking.type, "between_tools")
                test.is_false(has_block(sent[1].payload.messages, is_claude_thinking))
            end)

            it("removes marked blocks on Bedrock between_tools", function()
                local sent = capture_bedrock(bedrock_generate)
                assert(bedrock_generate.handler({ model = "m", messages = stale_rows(), options = {
                    max_tokens = 100, thinking_effort = 50,
                    request = { additionalModelRequestFields = { thinking = { type = "between_tools" } } } },
                    accepts = { thinking = "adaptive" } }))
                test.eq(sent[1].payload.additionalModelRequestFields.thinking.type, "between_tools")
                test.is_false(has_block(sent[1].payload.messages, is_bedrock_reasoning))
            end)

            it("removes marked blocks in Claude and Bedrock structured output", function()
                local sent = capture_claude(claude_structured)
                assert(claude_structured.handler({ model = "m", messages = stale_rows(), schema = SCHEMA, options = { max_tokens = 100 } }))
                test.is_false(has_block(sent[1].payload.messages, is_claude_thinking))
                sent = capture_claude(claude_structured)
                assert(claude_structured.handler({ model = "m", messages = stale_rows(), schema = SCHEMA,
                    options = { max_tokens = 100 }, accepts = { structured_output = "native" } }))
                test.is_false(has_block(sent[1].payload.messages, is_claude_thinking))
                sent = capture_bedrock(bedrock_structured)
                assert(bedrock_structured.handler({ model = "m", messages = stale_rows(), schema = SCHEMA, options = { max_tokens = 100 } }))
                test.is_false(has_block(sent[1].payload.messages, is_bedrock_reasoning))
            end)

            local BINDABLE = {
                { name = "always at effort 0", accepts = { thinking = "always" }, options = { max_tokens = 100 } },
                { name = "adaptive above 0", accepts = { thinking = "adaptive" }, options = { max_tokens = 100, thinking_effort = 30 } },
                { name = "budget above 0", accepts = { thinking = "budget" }, options = { max_tokens = 100, thinking_effort = 30 } },
            }
            for _, case in ipairs(BINDABLE) do
                it("keeps marked blocks bound on Claude: " .. case.name, function()
                    local sent = capture_claude(claude_generate)
                    assert(claude_generate.handler({ model = "m", messages = stale_rows(), options = case.options, accepts = case.accepts }))
                    test.is_true(has_block(sent[1].payload.messages, is_claude_thinking))
                    test.eq(sent[1].payload.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                    test.eq(sent[1].betas[1], BINDING_BETA)
                end)
                it("keeps marked blocks bound on Bedrock: " .. case.name, function()
                    local sent = capture_bedrock(bedrock_generate)
                    assert(bedrock_generate.handler({ model = "m", messages = stale_rows(), options = case.options, accepts = case.accepts }))
                    test.is_true(has_block(sent[1].payload.messages, is_bedrock_reasoning))
                    test.eq(sent[1].payload.additionalModelRequestFields.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                end)
            end

            it("decides from the object after the overlay", function()
                local sent = capture_claude(claude_generate)
                assert(claude_generate.handler({ model = "m", messages = stale_rows(), accepts = { thinking = "adaptive" }, options = {
                    max_tokens = 100, thinking_effort = 30, request = { thinking = { type = "disabled" } } } }))
                test.is_false(has_block(sent[1].payload.messages, is_claude_thinking))

                sent = capture_claude(claude_generate)
                assert(claude_generate.handler({ model = "m", messages = stale_rows(), accepts = { thinking = "none" }, options = {
                    max_tokens = 100, request = { thinking = { type = "adaptive" } } } }))
                test.is_true(has_block(sent[1].payload.messages, is_claude_thinking))
                test.eq(sent[1].payload.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
            end)

            it("leaves unmarked blocks on a request without a thinking object", function()
                local rows = stale_rows()
                rows[2].metadata.stale_thinking = nil
                local payload = claude_replay(rows)
                test.is_true(has_block(payload.messages, is_claude_thinking))
                payload = bedrock_replay(stale_rows())
                test.is_false(has_block(payload.messages, is_bedrock_reasoning))
            end)
        end)

        describe("interleaved response order", function()
            it("replays Claude JSON exactly", function()
                local result = claude_mapper.format_success_response({ content = CLAUDE_RESPONSE, stop_reason = "tool_use",
                    usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
                assert_order(claude_replay_order({ result = result.result, metadata = result.metadata }), RESPONSE_ORDER)
            end)

            it("replays Claude stream exactly", function()
                local _, stream_err, stream_result = claude_client.process_stream(sse_stream(claude_stream_events(CLAUDE_RESPONSE)), {})
                test.is_nil(stream_err)
                local result = claude_mapper.format_streaming_response(stream_result, {}, stream_result.usage, stream_result.finish_reason, stream_result.metadata)
                assert_order(claude_replay_order(result), RESPONSE_ORDER)
            end)

            it("replays Bedrock JSON exactly", function()
                local result = bedrock_mapper.format_success_response({ output = { message = { role = "assistant", content = BEDROCK_RESPONSE } },
                    stopReason = "tool_use", usage = { inputTokens = 1, outputTokens = 1 } }, {})
                assert_order(bedrock_replay_order(result), RESPONSE_ORDER)
            end)

            it("replays Bedrock stream exactly", function()
                local _, stream_err, stream_result = bedrock_client.process_converse_stream(bedrock_stream(BEDROCK_RESPONSE), {})
                test.is_nil(stream_err)
                local result = bedrock_mapper.format_streaming_response(stream_result, {}, stream_result.usage, stream_result.finish_reason, stream_result.metadata)
                assert_order(bedrock_replay_order(result), RESPONSE_ORDER)
            end)

            for _, path in ipairs(EXTRACTION_PATHS) do
                it("renders no blank layout text beside visible text: " .. path.name, function()
                    local result: any = path.extract({ "s1", "A", { "c1" }, "s2", "\n\n", { "c2" } })
                    test.eq(result.result.content, "A\n\n")
                    local payload = path.replay(stored_rows(result))
                    assert_order(path.order(payload.messages[2]), { "s1", "A", "c1", "s2", "c2" })
                end)

                for label, stored in pairs({
                    ["as received"] = " \n", ["as empty text"] = "", ["as other whitespace"] = "\t",
                }) do
                    it("keeps the order of a layout with only blank text stored " .. label .. ": " .. path.name, function()
                        local result: any = path.extract({ "s1", " ", { "c1" }, "s2", "\n", { "c2" } })
                        local rows = stored_rows(result)
                        rows[2].content = text(stored)
                        local payload = path.replay(rows)
                        assert_order(path.order(payload.messages[2]), { "s1", "c1", "s2", "c2" })
                    end)
                end

                it("keeps the order of a layout with only blank text stored with no content: " .. path.name, function()
                    local result: any = path.extract({ "s1", " ", { "c1" }, "s2", "\n", { "c2" } })
                    local rows = stored_rows(result)
                    rows[2].content = {}
                    local payload = path.replay(rows)
                    assert_order(path.order(payload.messages[2]), { "s1", "c1", "s2", "c2" })
                end)

                it("keeps the layout when the host trimmed the text: " .. path.name, function()
                    local result: any = path.extract({ "s1", "A", { "c1" }, "s2", "\n\n", { "c2" } })
                    local rows = stored_rows(result)
                    rows[2].content = text("A")
                    local payload = path.replay(rows)
                    assert_order(path.order(payload.messages[2]), { "s1", "A", "c1", "s2", "c2" })
                end)

                it("renders no whitespace text of a plain-order response: " .. path.name, function()
                    local result: any = path.extract({ "s1", "\n\n", { "c1" } })
                    test.is_nil(result.metadata.content_positions)
                    local payload = path.replay(stored_rows(result))
                    assert_order(path.order(payload.messages[2]), { "s1", "c1" })
                end)

                it("renders a turn with only blank layout text and no call as nothing: " .. path.name, function()
                    local result: any = path.extract({ "s1", " ", "s2", "\n" })
                    local rows = stored_rows(result)
                    table.insert(rows, { role = "user", content = text("next") })
                    local payload = path.replay(rows)
                    for _, message in ipairs(payload.messages) do
                        test.eq(message.role, "user")
                    end
                end)
            end

            it("sends no position field on the wire", function()
                local result = claude_mapper.format_success_response({ content = CLAUDE_RESPONSE, stop_reason = "tool_use",
                    usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
                local payload = claude_replay(stored_rows(result))
                test.is_false(json.encode(payload):find("position", 1, true) ~= nil)
            end)

            it("records nothing for a response the plain order reproduces", function()
                local result = claude_mapper.format_success_response({ content = {
                    { type = "thinking", thinking = "", signature = "s1" },
                    { type = "text", text = "only" },
                    { type = "tool_use", id = "c1", name = "t", input = { a = 1 } },
                }, stop_reason = "tool_use", usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
                test.is_nil(result.metadata.content_positions)
                test.is_nil(result.metadata.thinking_blocks[1].position)
            end)

            it("keeps today's order for stored rows without positions", function()
                local rows = {
                    { role = "user", content = text("q") },
                    { role = "assistant", content = text("before after"), metadata = {
                        thinking_blocks = { signed("s1"), signed("s2"), signed("s3") } } },
                    { role = "function_call", content = {}, function_call = { id = "c1", name = "t", arguments = {} } },
                    { role = "function_call", content = {}, function_call = { id = "c2", name = "t", arguments = {} } },
                    { role = "function_result", name = "t", function_call_id = "c1", content = text("r") },
                    { role = "function_result", name = "t", function_call_id = "c2", content = text("r") },
                }
                assert_order(claude_order(claude_replay(rows).messages[2]), { "s1", "s2", "s3", "before after", "c1", "c2" })
                assert_order(bedrock_order(bedrock_replay(rows).messages[2]), { "s1", "s2", "s3", "before after", "c1", "c2" })
            end)

            it("keeps the text and call order once the blocks are stripped", function()
                local result = claude_mapper.format_success_response({ content = CLAUDE_RESPONSE, stop_reason = "tool_use",
                    usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
                local rows = stored_rows({ result = result.result, metadata = result.metadata })
                rows[2].metadata.thinking_blocks = nil
                assert_order(claude_order(claude_replay(rows).messages[2]), { "before ", "c1", "c2", "after" })
            end)

            it("keeps the row's text when the host changed it", function()
                local result = claude_mapper.format_success_response({ content = CLAUDE_RESPONSE, stop_reason = "tool_use",
                    usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
                local rows = stored_rows({ result = result.result, metadata = result.metadata })
                rows[2].content = text("edited")
                assert_order(claude_order(claude_replay(rows).messages[2]), { "s1", "s2", "s3", "edited", "c1", "c2" })
            end)

            it("keeps two responses of one consolidated turn apart", function()
                local first = claude_mapper.format_success_response({ content = {
                    { type = "text", text = "a" }, { type = "thinking", thinking = "", signature = "s1" }, { type = "text", text = "b" },
                }, stop_reason = "end_turn", usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
                local second = claude_mapper.format_success_response({ content = {
                    { type = "text", text = "c" }, { type = "thinking", thinking = "", signature = "s2" }, { type = "text", text = "d" },
                }, stop_reason = "end_turn", usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
                local function row(result)
                    return { role = "assistant", content = text(result.result.content), metadata = {
                        thinking_blocks = result.metadata.thinking_blocks, content_positions = result.metadata.content_positions } }
                end
                local rows = { { role = "user", content = text("q") }, row(first), row(second), { role = "user", content = text("next") } }
                assert_order(claude_order(claude_replay(rows).messages[2]), { "a", "s1", "b", "c", "s2", "d" })
            end)

            it("keeps a Bedrock cache point behind the block it follows", function()
                local result = bedrock_mapper.format_success_response({ output = { message = { role = "assistant", content = BEDROCK_RESPONSE } },
                    stopReason = "tool_use", usage = { inputTokens = 1, outputTokens = 1 } }, {})
                local rows = stored_rows(result)
                table.insert(rows, 3, { role = "cache_marker", marker_id = "m" })
                assert_order(bedrock_order(bedrock_replay(rows).messages[2]),
                    { "s1", "before ", "s2", "c1", "s3", "c2", "after", "cachePoint" })
            end)

            it("takes no text layout from a recovered text tool call", function()
                local extracted = bedrock_mapper.extract_response_content({ output = { message = { content = {
                    reasoning_block("s1"), { text = "a" }, { text = '{"name":"t","arguments":{}}' },
                } } } }, { t = "app:t" })
                test.eq(#extracted.tool_calls, 1)
                test.is_nil(extracted.content_positions)
            end)
        end)

        describe("OpenAI-compatible tool rounds", function()
            local function note_rows()
                return {
                    { role = "user", content = text("q") },
                    { role = "assistant", content = text("look") },
                    { role = "function_call", content = {}, function_call = { id = "c1", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c1", content = text("r1") },
                    { role = "system", content = text("NOTE"), metadata = { preserve_position = true } },
                    { role = "function_call", content = {}, function_call = { id = "c2", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c2", content = text("r2") },
                }
            end

            it("keeps a positional note between tool rounds in place", function()
                local mapped: any = compat_mapper.map_messages(note_rows(), { model = "gpt" })
                local roles = {}
                for _, message in ipairs(mapped) do table.insert(roles, message.role) end
                assert_order(roles, { "user", "assistant", "tool", "system", "assistant", "tool" })
                test.eq(#mapped[2].tool_calls, 1)
                test.eq(mapped[2].tool_calls[1].id, "c1")
                test.eq(mapped[4].content[1].text, "NOTE")
                test.eq(mapped[5].tool_calls[1].id, "c2")
                test.eq(mapped[6].tool_call_id, "c2")
            end)

            it("keeps parallel calls of one round on one assistant message", function()
                local mapped: any = compat_mapper.map_messages({
                    { role = "assistant", content = text("look") },
                    { role = "function_call", content = {}, function_call = { id = "c1", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c1", content = text("r1") },
                    { role = "function_call", content = {}, function_call = { id = "c2", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c2", content = text("r2") },
                }, { model = "gpt" })
                test.eq(#mapped[1].tool_calls, 2)
            end)

            it("reads past a cache marker between rounds", function()
                local mapped: any = compat_mapper.map_messages({
                    { role = "assistant", content = text("look") },
                    { role = "function_call", content = {}, function_call = { id = "c1", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c1", content = text("r1") },
                    { role = "cache_marker", marker_id = "m" },
                    { role = "function_call", content = {}, function_call = { id = "c2", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c2", content = text("r2") },
                }, { model = "gpt" })
                test.eq(#mapped[1].tool_calls, 2)
            end)
        end)

        describe("blank assistant turns", function()
            local function blank_rows(row)
                return { { role = "user", content = text("Q") }, row, { role = "user", content = text("Q2") } }
            end
            local BLANKS = {
                { name = "empty text", row = { role = "assistant", content = text("") } },
                { name = "whitespace text", row = { role = "assistant", content = text(" \n\t") } },
                { name = "no content", row = { role = "assistant", content = {} } },
                { name = "string blank", row = { role = "assistant", content = "  " } },
                { name = "thinking only", row = { role = "assistant", content = {}, metadata = { thinking_blocks = { signed("s1") } } } },
                { name = "thinking and whitespace", row = { role = "assistant", content = text(" "), metadata = { thinking_blocks = { signed("s1") } } } },
            }
            for _, case in ipairs(BLANKS) do
                it("renders nothing on Claude: " .. case.name, function()
                    local mapped = claude_mapper.map_messages(blank_rows(case.row))
                    test.eq(#mapped.messages, 2)
                    test.eq(mapped.messages[1].role, "user")
                    test.eq(mapped.messages[2].role, "user")
                    test.is_false(json.encode(mapped.messages):find("intercepted", 1, true) ~= nil)
                end)
                it("renders nothing on Bedrock: " .. case.name, function()
                    local mapped = bedrock_mapper.map_messages(blank_rows(case.row))
                    test.eq(#mapped.messages, 1)
                    test.eq(mapped.messages[1].role, "user")
                    test.eq(#mapped.messages[1].content, 2)
                end)
                it("renders nothing on OpenAI: " .. case.name, function()
                    local items = openai_mapper.map_messages(blank_rows(case.row), {})
                    test.eq(#items, 2)
                    test.eq(items[1].role, "user")
                    test.eq(items[2].role, "user")
                end)
                it("renders nothing on OpenAI-compatible: " .. case.name, function()
                    local mapped = compat_mapper.map_messages(blank_rows(case.row), {})
                    test.eq(#mapped, 2)
                    test.eq(mapped[2].role, "user")
                end)
                it("renders nothing on Google: " .. case.name, function()
                    local mapped = google_mapper.map_messages(blank_rows(case.row), {})
                    test.eq(#mapped, 2)
                    test.eq(mapped[2].role, "user")
                end)
            end

            it("drops only the blank parts of an OpenAI assistant message", function()
                local items = openai_mapper.map_messages({
                    { role = "user", content = text("Q") },
                    { role = "assistant", content = { { type = "text", text = " " }, { type = "text", text = "kept" }, { type = "text", text = "" } } },
                }, {})
                test.eq(#items[2].content, 1)
                test.eq(items[2].content[1].text, "kept")
            end)

            it("keeps a turn that has a call on every driver", function()
                local rows = {
                    { role = "user", content = text("Q") },
                    { role = "assistant", content = text(""), metadata = { thinking_blocks = { signed("s1") } } },
                    { role = "function_call", content = {}, function_call = { id = "c1", name = "t", arguments = "{\"a\":1}" } },
                    { role = "function_result", name = "t", function_call_id = "c1", content = text("r") },
                }
                assert_order(claude_order(claude_mapper.map_messages(rows).messages[2]), { "s1", "c1" })
                assert_order(bedrock_order(bedrock_mapper.map_messages(rows).messages[2]), { "s1", "c1" })
                test.eq(openai_mapper.map_messages(rows, {})[2].type, "function_call")
                test.eq((compat_mapper.map_messages(rows, {}) :: any)[2].tool_calls[1].id, "c1")
                test.not_nil(google_mapper.map_messages(rows, {})[2].parts[1].functionCall)
            end)

            it("sends no whitespace text inside a turn with a call on any driver", function()
                local rows = {
                    { role = "user", content = text("Q") },
                    { role = "assistant", content = text("\n\n") },
                    { role = "function_call", content = {}, function_call = { id = "c1", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c1", content = text("r") },
                }
                assert_order(claude_order(claude_mapper.map_messages(rows).messages[2]), { "c1" })
                assert_order(bedrock_order(bedrock_mapper.map_messages(rows).messages[2]), { "c1" })
                test.eq(openai_mapper.map_messages(rows, {})[2].type, "function_call")
                test.not_nil(google_mapper.map_messages(rows, {})[2].parts[1].functionCall)
                test.eq((compat_mapper.map_messages(rows, {}) :: any)[2].content, "")
            end)

            it("sends no whitespace string content inside a turn with a call", function()
                local rows = {
                    { role = "user", content = text("Q") },
                    { role = "assistant", content = "  " },
                    { role = "function_call", content = {}, function_call = { id = "c1", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c1", content = text("r") },
                }
                assert_order(claude_order(claude_mapper.map_messages(rows).messages[2]), { "c1" })
                assert_order(bedrock_order(bedrock_mapper.map_messages(rows).messages[2]), { "c1" })
            end)

            it("drops a whitespace part beside visible text", function()
                local rows = {
                    { role = "user", content = text("Q") },
                    { role = "assistant", content = { { type = "text", text = " " }, { type = "text", text = "kept" } } },
                    { role = "user", content = text("Q2") },
                }
                assert_order(claude_order(claude_mapper.map_messages(rows).messages[2]), { "kept" })
                assert_order(bedrock_order(bedrock_mapper.map_messages(rows).messages[2]), { "kept" })
            end)

            it("keeps outer whitespace of visible text", function()
                local rows = {
                    { role = "user", content = text("Q") },
                    { role = "assistant", content = text(" kept\n") },
                    { role = "user", content = text("Q2") },
                }
                assert_order(claude_order(claude_mapper.map_messages(rows).messages[2]), { " kept\n" })
                assert_order(bedrock_order(bedrock_mapper.map_messages(rows).messages[2]), { " kept\n" })
            end)

            it("moves a cache marker off a blank turn", function()
                local mapped = claude_mapper.map_messages({
                    { role = "user", content = text("Q") },
                    { role = "assistant", content = text("  ") },
                    { role = "cache_marker", marker_id = "tail" },
                })
                test.eq(#mapped.messages, 1)
                test.not_nil(mapped.messages[1].content[1].cache_control)
            end)
        end)

        describe("effective output", function()
            local function setup(handler, method, card, policy)
                llm._usage_tracker = false
                use_card(card)
                llm._providers = policy_providers(handler, method, policy or BUDGET_POLICY)
            end

            local function card(fields)
                local out = { name = "m", id = "m", capabilities = {}, class = {},
                    providers = { { id = "route", provider_model = "wire" } } }
                for key, value in pairs(fields) do out[key] = value end
                return out
            end

            it("clamps the Claude budget raise to the card limit and reports the wire value", function()
                local sent = capture_claude(claude_generate)
                setup(claude_generate, "generate", card({ output_tokens = 8192 }))
                local result: any = assert(llm.generate("hi", { model = "m", max_tokens = 512, thinking_effort = 100 }))
                test.eq(sent[1].payload.max_tokens, 8192)
                test.eq(sent[1].payload.thinking.budget_tokens, 7168)
                test.eq(result.metadata.adjusted.max_tokens.requested, 512)
                test.eq(result.metadata.adjusted.max_tokens.sent, 8192)
                test.eq(result.metadata.adjusted.thinking_budget.requested, 24000)
                test.eq(result.metadata.adjusted.thinking_budget.sent, 7168)
            end)

            it("clamps the Bedrock budget raise to the card limit and reports the wire value", function()
                local sent = capture_bedrock(bedrock_generate)
                setup(bedrock_generate, "generate", card({ output_tokens = 8192 }))
                local result: any = assert(llm.generate("hi", { model = "m", max_tokens = 512, thinking_effort = 100 }))
                test.eq(sent[1].payload.inferenceConfig.maxTokens, 8192)
                test.eq(sent[1].payload.additionalModelRequestFields.thinking.budget_tokens, 7168)
                test.eq(result.metadata.adjusted.max_tokens.sent, 8192)
            end)

            it("reports a raise with no limit in the way", function()
                local sent = capture_claude(claude_generate)
                setup(claude_generate, "generate", card({}))
                local result: any = assert(llm.generate("hi", { model = "m", max_tokens = 512, thinking_effort = 100 }))
                test.eq(sent[1].payload.max_tokens, 25024)
                test.eq(sent[1].payload.thinking.budget_tokens, 24000)
                test.eq(result.metadata.adjusted.max_tokens.requested, 512)
                test.eq(result.metadata.adjusted.max_tokens.sent, 25024)
                test.is_nil(result.metadata.adjusted.thinking_budget)
            end)

            it("leaves a request above the budget and under the limit alone", function()
                local sent = capture_claude(claude_generate)
                setup(claude_generate, "generate", card({ output_tokens = 64000 }))
                local result: any = assert(llm.generate("hi", { model = "m", max_tokens = 30000, thinking_effort = 100 }))
                test.eq(sent[1].payload.max_tokens, 30000)
                test.eq(sent[1].payload.thinking.budget_tokens, 24000)
                test.is_nil(result.metadata.adjusted)
            end)

            it("rejects the raise under strict", function()
                capture_claude(claude_generate)
                setup(claude_generate, "generate", card({}))
                local result, err = llm.generate("hi", { model = "m", max_tokens = 512, thinking_effort = 100, strict = true })
                test.is_nil(result)
                test.contains(tostring(err), "max_tokens")
            end)

            it("gives up thinking when the limit leaves no room for the minimum budget", function()
                local sent = capture_claude(claude_generate)
                setup(claude_generate, "generate", card({ output_tokens = 1000 }))
                local result: any = assert(llm.generate("hi", { model = "m", max_tokens = 512, thinking_effort = 100 }))
                test.is_nil(sent[1].payload.thinking)
                test.eq(sent[1].payload.max_tokens, 512)
                test.eq(result.metadata.adjusted.thinking_effort.requested, 100)
            end)

            it("admits on the raised output", function()
                local sent = capture_claude(claude_generate)
                setup(claude_generate, "generate", card({ max_tokens = 30000 }))
                local result, err = llm.generate(string.rep("x", 80000), { model = "m", max_tokens = 512, thinking_effort = 100 })
                test.is_nil(result)
                test.contains(tostring(err), "context window")
                test.eq(#sent, 0)
            end)

            it("reserves the driver default when max_tokens is unset", function()
                local sent = capture_claude(claude_generate)
                setup(claude_generate, "generate", card({ max_tokens = 1000 }))
                local result, err = llm.generate(string.rep("x", 800), { model = "m" })
                test.is_nil(result)
                test.contains(tostring(err), "context window")
                test.eq(#sent, 0)
            end)

            it("keeps the wire default for an unset max_tokens under the limit without adjustment", function()
                local sent = capture_bedrock(bedrock_generate)
                setup(bedrock_generate, "generate", card({ output_tokens = 64000 }))
                local result: any = assert(llm.generate("hi", { model = "m" }))
                test.eq(sent[1].payload.inferenceConfig.maxTokens, 2000)
                test.is_nil(result.metadata.adjusted)
            end)

            it("clamps the driver default to the card limit", function()
                local sent = capture_claude(claude_generate)
                setup(claude_generate, "generate", card({ output_tokens = 1000 }))
                local result: any = assert(llm.generate("hi", { model = "m" }))
                test.eq(sent[1].payload.max_tokens, 1000)
                test.is_nil(result.metadata.adjusted)
            end)

            it("applies to structured output", function()
                local sent = capture_claude(claude_structured)
                setup(claude_structured, "structured_output", card({ output_tokens = 8192 }))
                local result: any = assert(llm.structured_output(SCHEMA, "hi", { model = "m", max_tokens = 512, thinking_effort = 100 }))
                test.eq(sent[1].payload.max_tokens, 8192)
                test.eq(result.metadata.adjusted.max_tokens.sent, 8192)
            end)

            it("leaves a driver without a policy to its request", function()
                local sent = capture_openai(openai_generate)
                setup(openai_generate, "generate", card({ max_tokens = 1000 }), false)
                llm._providers.driver_output_policy = function() return nil, nil end
                assert(llm.generate(string.rep("x", 800), { model = "m" }))
                test.is_nil(sent[1].payload.max_output_tokens)
            end)

            it("declares the policy on the real driver bindings", function()
                for _, driver in ipairs({
                    { id = "wippy.llm.claude:driver", mapper = claude_mapper },
                    { id = "wippy.llm.bedrock:driver", mapper = bedrock_mapper },
                }) do
                    local entry = assert(registry.get(driver.id))
                    test.eq(entry.meta.output_policy.thinking, driver.mapper.CAPABILITY.defaults.thinking)
                    test.eq(entry.meta.output_policy.default_max_tokens, driver.mapper.DEFAULT_MAX_TOKENS)
                end
                test.is_nil(assert(registry.get("wippy.llm.openai:driver")).meta.output_policy)
            end)

            it("reads the policy through the provider discovery", function()
                local entry = assert(registry.get("wippy.llm.bedrock:provider"))
                local policy, err = providers.driver_output_policy(entry.id)
                test.is_nil(err)
                test.eq(policy.thinking, "budget")
                test.eq(policy.default_max_tokens, 2000)
            end)
        end)

        describe("blank user, system and developer text", function()
            local function rows()
                return {
                    { role = "system", content = text("") },
                    { role = "system", content = " \n" },
                    { role = "system", content = text("S") },
                    { role = "user", content = { { type = "text", text = "  " }, { type = "text", text = "Q" } } },
                    { role = "user", content = text("\t") },
                    { role = "developer", content = text(" ") },
                    { role = "developer", content = text(""), metadata = { preserve_position = true } },
                    { role = "system", content = text(" "), metadata = { preserve_position = true } },
                }
            end

            it("never reaches Claude", function()
                local mapped = claude_mapper.map_messages(rows())
                test.eq(#mapped.system, 1)
                test.eq(mapped.system[1].text, "S")
                test.eq(#mapped.messages, 1)
                test.eq(#mapped.messages[1].content, 1)
                test.eq(mapped.messages[1].content[1].text, "Q")
            end)

            it("never reaches Bedrock", function()
                local mapped = bedrock_mapper.map_messages(rows())
                test.eq(#mapped.system, 1)
                test.eq(#mapped.messages, 1)
                test.eq(#mapped.messages[1].content, 1)
            end)

            it("never reaches OpenAI", function()
                local input = rows()
                test.eq(openai_mapper.extract_instructions(input), "S")
                local items = openai_mapper.map_messages(input, {})
                test.eq(#items, 1)
                test.eq(#items[1].content, 1)
            end)

            it("never reaches OpenAI-compatible", function()
                local mapped = compat_mapper.map_messages(rows(), {})
                test.eq(#mapped, 2)
                test.eq(mapped[1].role, "system")
                test.eq(mapped[2].role, "user")
                test.eq(#mapped[2].content, 1)
            end)

            it("never reaches OpenAI-compatible structured output", function()
                local sent = capture_openai(compat_structured)
                compat_structured.handler({ model = "m", messages = rows(), schema = SCHEMA, options = {} })
                test.eq(#sent[1].payload.messages, 2)
            end)

            it("never reaches Google", function()
                local mapped, system = google_mapper.map_messages(rows(), {})
                test.eq(#system, 1)
                test.eq(#mapped, 1)
                test.eq(#mapped[1].parts, 1)
            end)

            it("sends no blank part in place of a part OpenAI cannot render", function()
                local document = { type = "document", source = { type = "base64", mime_type = "application/pdf", data = "BBBB" } }
                local items = openai_mapper.map_messages({
                    { role = "user", content = { { type = "text", text = "See" }, document } },
                    { role = "user", content = { document } },
                }, {})
                test.eq(#items, 1)
                test.eq(#items[1].content, 1)
            end)

            it("keeps an image beside blank text", function()
                local image = { type = "image", source = { type = "base64", mime_type = "image/png", data = "AAAA" } }
                local mapped = claude_mapper.map_messages({ { role = "user", content = { { type = "text", text = " " }, image } } })
                test.eq(#mapped.messages[1].content, 1)
                test.eq(mapped.messages[1].content[1].type, "image")
            end)

            it("keeps an empty tool result", function()
                local mapped = claude_mapper.map_messages({
                    { role = "function_call", content = {}, function_call = { id = "c1", name = "t", arguments = "{}" } },
                    { role = "function_result", name = "t", function_call_id = "c1", content = text("") },
                })
                test.eq(mapped.messages[2].content[1].type, "tool_result")
            end)

            it("leaves the caller's rows untouched", function()
                local input = rows()
                claude_mapper.map_messages(input)
                test.eq(#input, 8)
                test.eq(#input[4].content, 2)
            end)
        end)

        describe("requests with no turn", function()
            local SYSTEM_ONLY = { { role = "system", content = text("S") } }
            local BLANK_USER = { { role = "user", content = text("  ") } }
            local CASES = {
                { name = "Claude generate", handler = claude_generate, capture = capture_claude },
                { name = "Claude structured", handler = claude_structured, capture = capture_claude, schema = true },
                { name = "Claude native structured", handler = claude_structured, capture = capture_claude, schema = true, accepts = { structured_output = "native" } },
                { name = "Bedrock generate", handler = bedrock_generate, capture = capture_bedrock },
                { name = "Bedrock structured", handler = bedrock_structured, capture = capture_bedrock, schema = true },
                { name = "Google generate", handler = google_generate, capture = capture_google },
                { name = "Google structured", handler = google_structured, capture = capture_google, schema = true },
                { name = "OpenAI generate", handler = openai_generate, capture = capture_openai },
                { name = "OpenAI structured", handler = openai_structured, capture = capture_openai, schema = true },
            }
            for _, case in ipairs(CASES) do
                for label, messages in pairs({ ["system only"] = SYSTEM_ONLY, ["blank user"] = BLANK_USER }) do
                    it("rejects before HTTP on " .. case.name .. ": " .. label, function()
                        local sent = case.capture(case.handler)
                        local response, err = case.handler.handler({ model = "m", messages = messages, options = {},
                            accepts = case.accepts, schema = case.schema and SCHEMA or nil })
                        test.is_nil(response)
                        test.eq(#sent, 0)
                        test.eq(err:kind(), "Invalid")
                        test.contains(err:message(), "no conversation turn")
                    end)
                end
            end

            it("still sends a system-role note alone on OpenAI", function()
                local sent = capture_openai(openai_generate)
                assert(openai_generate.handler({ model = "m", options = {}, messages = {
                    { role = "system", content = text("N"), metadata = { preserve_position = true } } } }))
                test.eq(#sent, 1)
                test.eq(#sent[1].payload.input, 1)
            end)

            it("still sends a system message alone on OpenAI-compatible", function()
                local sent = capture_openai(compat_generate)
                assert(compat_generate.handler({ model = "m", options = {}, messages = SYSTEM_ONLY }))
                test.eq(#sent, 1)
                test.eq(#sent[1].payload.messages, 1)
            end)
        end)

        describe("drop_stale_thinking on string content", function()
            it("handles an assistant message with string content", function()
                local builder: any = prompt.new({
                    { role = "user", content = "q" },
                    { role = "assistant", content = "hi", metadata = { thinking_blocks = { signed("A") } } },
                    { role = "user", content = "q2" },
                } :: any)
                local ok, result, err = pcall(function() return builder:drop_stale_thinking(function() return false end) end)
                test.is_true(ok)
                test.is_nil(err)
                test.is_nil(result.messages[2].metadata.thinking_blocks)
            end)
        end)

        describe("mark_stale_thinking", function()
            it("marks every block carrier up to the last stale one on copies", function()
                local first = { role = "assistant", content = text("a"), metadata = { thinking_blocks = { signed("A") }, epoch = "old" } }
                local second = { role = "assistant", content = text("b"), metadata = { thinking_blocks = { signed("B") }, epoch = "new" } }
                local third = { role = "assistant", content = text("c"), metadata = { thinking_blocks = { signed("C") }, epoch = "new" } }
                local builder: any = prompt.new({ { role = "user", content = text("q") }, second, first, third } :: any)
                builder:mark_stale_thinking(function(msg) return msg.metadata.epoch == "new" end)
                test.is_true(builder.messages[2].metadata.stale_thinking)
                test.is_true(builder.messages[3].metadata.stale_thinking)
                test.is_nil(builder.messages[4].metadata.stale_thinking)
                test.is_nil(first.metadata.stale_thinking)
                test.is_nil(second.metadata.stale_thinking)
            end)

            it("handles rows without blocks and string content", function()
                local builder: any = prompt.new({
                    { role = "user", content = "q" },
                    { role = "assistant", content = "hi" },
                } :: any)
                builder:mark_stale_thinking(function() return false end)
                test.is_nil(builder.messages[2].metadata)
            end)
        end)
    end)
end

return test.run_cases(define_tests)
