local test = require("test")
local json = require("json")
local llm = require("llm")
local prompt = require("prompt")
local agent = require("agent")
local claude_generate = require("claude_generate")
local bedrock_generate = require("bedrock_generate")
local claude_mapper = require("claude_mapper")
local claude_client = require("claude_client")
local bedrock_mapper = require("bedrock_mapper")
local bedrock_client = require("bedrock_client")

local BUDGET_POLICY = { thinking = "budget", default_max_tokens = 2000 }

local function text(value) return { { type = "text", text = value } } end
local function blocks(name) return { { type = "thinking", thinking = "", signature = "sig-" .. name } } end

local function install(route): any
    local sent: any = {}
    claude_generate._client = { ENDPOINTS = { MESSAGES = "/messages" }, request = function(_, payload, options)
        table.insert(sent, { payload = payload, betas = options and options.beta_features })
        return { content = { { type = "text", text = "ok" } }, stop_reason = "end_turn",
            usage = { input_tokens = 1, output_tokens = 1 }, metadata = {} }
    end }
    bedrock_generate._client = { converse = function(_, payload)
        table.insert(sent, { payload = payload })
        return { output = { message = { role = "assistant", content = { { text = "ok" } } } }, stopReason = "end_turn",
            usage = { inputTokens = 1, outputTokens = 1 }, metadata = {} }
    end }
    llm._usage_tracker = false
    local card = { name = "m", id = "m", capabilities = {}, class = {}, max_tokens = 200000, output_tokens = 64000, providers = { route } }
    llm._models = { get_by_name = function() return card, nil end, get_by_class = function() return {}, nil end }
    llm._providers = {
        driver_declares_legacy_reasoning_flag = function() return false end,
        driver_output_policy = function() return BUDGET_POLICY, nil end,
        open = function(id)
            local handler = id:match("^bedrock") and bedrock_generate or claude_generate
            return { generate = function(_, args) return handler.handler(args) end }
        end,
    }
    return sent
end

local function spec(id, effort, prompt_text)
    return { id = id, name = id, description = id, model = "m", max_tokens = 4096, thinking_effort = effort,
        prompt = prompt_text == nil and ("You are " .. id) or prompt_text,
        tools = { lookup = { name = "lookup", description = "d", schema = { type = "object", properties = {} },
            registry_id = "app:lookup", context = {} } },
        memory = {}, prompt_funcs = {}, step_funcs = {}, tool_wrappers = {} }
end

-- Agent A thinks and hands off inside a tool round; B runs the next step.
local function handoff_history()
    local answer = { role = "assistant", content = text("handing off"), metadata = {
        thinking_blocks = blocks("A"), prefix_fingerprint = "fingerprint-of-agent-a" } }
    local builder = prompt.new({ { role = "user", content = text("q1") }, answer } :: any)
    builder:add_function_call("handoff", '{"to":"b"}', "c1")
    builder:add_function_result("handoff", "ok", "c1")
    return builder, answer
end

local function has(content, field)
    for _, part in ipairs(content) do
        if part[field] ~= nil then return true end
    end
    return false
end

local function claude_thinking(content)
    for _, part in ipairs(content) do
        if part.type == "thinking" then return true end
    end
    return false
end

local ROUTES = {
    { driver = "Claude", id = "claude_route", between = { thinking = { type = "between_tools" } } },
    { driver = "Bedrock", id = "bedrock_route",
        between = { additionalModelRequestFields = { thinking = { type = "between_tools" } } } },
}

local function carries_blocks(route, sent)
    local turn = sent[1].payload.messages[2]
    if route.driver == "Claude" then return claude_thinking(turn.content) end
    return has(turn.content, "reasoningContent")
end

local function sent_thinking(route, sent)
    if route.driver == "Claude" then return sent[1].payload.thinking end
    local fields = sent[1].payload.additionalModelRequestFields
    return fields and fields.thinking
end

local function claude_blocks(shape)
    local out = {}
    for _, item in ipairs(shape) do
        if type(item) == "table" then
            table.insert(out, { type = "tool_use", id = item[1], name = "lookup", input = { a = 1 } })
        elseif item:match("^s%d$") then
            table.insert(out, { type = "thinking", thinking = "", signature = item })
        else
            table.insert(out, { type = "text", text = item })
        end
    end
    return out
end

local function bedrock_blocks(shape)
    local out = {}
    for _, item in ipairs(shape) do
        if type(item) == "table" then
            table.insert(out, { toolUse = { toolUseId = item[1], name = "lookup", input = { a = 1 } } })
        elseif item:match("^s%d$") then
            table.insert(out, { reasoningContent = { reasoningText = { text = "", signature = item } } })
        else
            table.insert(out, { text = item })
        end
    end
    return out
end

local function claude_stream(shape)
    local body = ""
    local function add(name, data) body = body .. "event: " .. name .. "\ndata: " .. json.encode(data) .. "\n\n" end
    add("message_start", { message = { usage = { input_tokens = 1 } } })
    for index, block in ipairs(claude_blocks(shape)) do
        local at = index - 1
        if block.type == "thinking" then
            add("content_block_start", { index = at, content_block = { type = "thinking", thinking = "", signature = "" } })
            add("content_block_delta", { index = at, delta = { type = "signature_delta", signature = block.signature } })
        elseif block.type == "text" then
            add("content_block_start", { index = at, content_block = { type = "text", text = "" } })
            add("content_block_delta", { index = at, delta = { type = "text_delta", text = block.text } })
        else
            add("content_block_start", { index = at, content_block = { type = "tool_use", id = block.id, name = block.name } })
            add("content_block_delta", { index = at, delta = { type = "input_json_delta", partial_json = '{"a":' } })
        end
        add("content_block_stop", { index = at })
    end
    add("message_delta", { delta = { stop_reason = "max_tokens" }, usage = { output_tokens = 2 } })
    add("message_stop", {})
    local done = false
    return { stream = { read = function()
        if done then return nil end
        done = true
        return body
    end }, metadata = {} }
end

local function bedrock_stream(shape)
    local function header(name, value)
        return string.char(#name) .. name .. string.char(7) .. string.pack(">I2", #value) .. value
    end
    local chunks = {}
    local function add(name, data)
        local headers = header(":event-type", name) .. header(":content-type", "application/json")
            .. header(":message-type", "event")
        local payload = json.encode(data)
        local total = 12 + #headers + #payload + 4
        table.insert(chunks, string.pack(">I4I4I4", total, #headers, 0) .. headers .. payload .. string.pack(">I4", 0))
    end
    add("messageStart", { role = "assistant" })
    for index, block in ipairs(bedrock_blocks(shape)) do
        local at = index - 1
        if block.reasoningContent then
            add("contentBlockDelta", { contentBlockIndex = at, delta = { reasoningContent = {
                signature = block.reasoningContent.reasoningText.signature } } })
        elseif block.text then
            add("contentBlockDelta", { contentBlockIndex = at, delta = { text = block.text } })
        else
            add("contentBlockStart", { contentBlockIndex = at, start = { toolUse = { toolUseId = block.toolUse.toolUseId, name = "lookup" } } })
            add("contentBlockDelta", { contentBlockIndex = at, delta = { toolUse = { input = '{"a":' } } })
        end
        add("contentBlockStop", { contentBlockIndex = at })
    end
    add("messageStop", { stopReason = "max_tokens" })
    add("metadata", { usage = { inputTokens = 1, outputTokens = 2 } })
    local at = 0
    return { stream = { read = function()
        at = at + 1
        return chunks[at]
    end }, metadata = {} }
end

local function claude_replay(rows)
    local sent = install({ id = "claude_route", provider_model = "wire" })
    assert(claude_generate.handler({ model = "m", messages = rows, options = { max_tokens = 100 } }))
    return sent[1].payload.messages
end

local function bedrock_replay(rows)
    local sent = install({ id = "bedrock_route", provider_model = "wire" })
    assert(bedrock_generate.handler({ model = "m", messages = rows, options = { max_tokens = 100 } }))
    return sent[1].payload.messages
end

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
        table.insert(order, reasoning and reasoning.signature or (part.toolUse and part.toolUse.toolUseId) or part.text or "other")
    end
    return order
end

local TRUNCATED_PATHS: any = {
    { name = "Claude JSON", replay = claude_replay, order = claude_order, extract = function(shape)
        return claude_mapper.format_success_response({ content = claude_blocks(shape), stop_reason = "max_tokens",
            usage = { input_tokens = 1, output_tokens = 1 } }, "m", {})
    end },
    { name = "Claude stream", replay = claude_replay, order = claude_order, extract = function(shape)
        local _, _, stream = claude_client.process_stream(claude_stream(shape), {})
        return claude_mapper.format_streaming_response(stream, {}, stream.usage, stream.finish_reason, stream.metadata)
    end },
    { name = "Bedrock JSON", replay = bedrock_replay, order = bedrock_order, extract = function(shape)
        return bedrock_mapper.format_success_response({ output = { message = { role = "assistant", content = bedrock_blocks(shape) } },
            stopReason = "max_tokens", usage = { inputTokens = 1, outputTokens = 1 } }, {})
    end },
    { name = "Bedrock stream", replay = bedrock_replay, order = bedrock_order, extract = function(shape)
        local _, _, stream = bedrock_client.process_converse_stream(bedrock_stream(shape), {})
        return bedrock_mapper.format_streaming_response(stream, {}, stream.usage, stream.finish_reason, stream.metadata)
    end },
}

-- The step of an agent on a length-limited response, then the request a host sends
-- after persisting what the step returned.
local function replay_after_truncation(path, shape)
    local extracted = path.extract(shape)
    agent._llm = { generate = function()
        return { result = extracted.result.content, tool_calls = extracted.result.tool_calls,
            finish_reason = extracted.finish_reason, metadata = extracted.metadata, tokens = {} }
    end }
    local builder = prompt.new()
    builder:add_user("q")
    local response = assert(agent.new(spec("agent_a", 0)):step(builder, {}))
    agent._llm = nil
    test.is_true(response.truncated)
    test.is_nil(response.tool_calls)
    local messages = path.replay({
        { role = "user", content = text("q") },
        { role = "assistant", content = text(response.result), metadata = {
            thinking_blocks = response.metadata.thinking_blocks,
            content_positions = response.metadata.content_positions,
            prefix_fingerprint = response.prefix_fingerprint } },
        { role = "user", content = text("try again") },
    })
    for _, message in ipairs(messages) do
        if message.role == "assistant" then return path.order(message), response end
    end
    return {}, response
end

local function define_tests()
    describe("Agent replay safety", function()
        after_each(function()
            llm._providers = nil
            llm._models = nil
            llm._usage_tracker = nil
            claude_generate._client = nil
            bedrock_generate._client = nil
            agent._llm = nil
        end)

        for _, route in ipairs(ROUTES) do
            local UNBINDABLE = {
                { name = "default budget", thinking = nil, effort = 0 },
                { name = "adaptive at effort 0", thinking = "adaptive", effort = 0 },
                { name = "none", thinking = "none", effort = 0 },
                { name = "none with a positive effort", thinking = "none", effort = 40 },
            }
            for _, case in ipairs(UNBINDABLE) do
                it("sends no stale block on " .. route.driver .. ": " .. case.name, function()
                    local sent = install({ id = route.id, provider_model = "wire", thinking = case.thinking })
                    local builder, answer = handoff_history()
                    assert(agent.new(spec("agent_b", case.effort)):step(builder, { drop_stale_thinking = true }))
                    test.is_false(carries_blocks(route, sent))
                    test.is_nil(sent_thinking(route, sent))
                    test.eq(answer.metadata.thinking_blocks[1].signature, "sig-A")
                    test.is_nil(answer.metadata.stale_thinking)
                end)
            end

            it("sends no stale block on " .. route.driver .. ": between_tools", function()
                local sent = install({ id = route.id, provider_model = "wire", thinking = "adaptive",
                    options = { request = route.between } })
                local builder = handoff_history()
                assert(agent.new(spec("agent_b", 30)):step(builder, { drop_stale_thinking = true }))
                test.is_false(carries_blocks(route, sent))
                test.eq(sent_thinking(route, sent).type, "between_tools")
            end)

            local BINDABLE = {
                { name = "always at effort 0", thinking = "always", effort = 0 },
                { name = "adaptive above effort 0", thinking = "adaptive", effort = 30 },
            }
            for _, case in ipairs(BINDABLE) do
                it("keeps the stale block bound on " .. route.driver .. ": " .. case.name, function()
                    local sent = install({ id = route.id, provider_model = "wire", thinking = case.thinking })
                    local builder = handoff_history()
                    assert(agent.new(spec("agent_b", case.effort)):step(builder, { drop_stale_thinking = true }))
                    test.is_true(carries_blocks(route, sent))
                    test.eq(sent_thinking(route, sent).block_binding.prefix_mismatch_behavior, "drop_block")
                end)
            end

            it("keeps a current block on an effort-0 " .. route.driver .. " step", function()
                local sent = install({ id = route.id, provider_model = "wire" })
                local probe = prompt.new()
                probe:add_user("x")
                local fingerprint = assert(agent.new(spec("agent_b", 0)):step(probe, {})).prefix_fingerprint
                sent = install({ id = route.id, provider_model = "wire" })
                local builder, answer = handoff_history()
                answer.metadata.prefix_fingerprint = fingerprint
                assert(agent.new(spec("agent_b", 0)):step(builder, { drop_stale_thinking = true }))
                test.is_true(carries_blocks(route, sent))
            end)

            it("sends no empty system block for an empty prompt on " .. route.driver, function()
                for _, empty in ipairs({ "", "  \n" }) do
                    local sent = install({ id = route.id, provider_model = "wire" })
                    local builder = prompt.new()
                    builder:add_user("q")
                    assert(agent.new(spec("agent_b", 0, empty)):step(builder, {}))
                    test.is_nil(sent[1].payload.system)
                end
            end)
        end

        for _, path in ipairs(TRUNCATED_PATHS) do
            it("never replays thinking behind a discarded call: text, thinking, call: " .. path.name, function()
                local order, response = replay_after_truncation(path, { "A", "s1", { "c1" } })
                test.eq(table.concat(order, "|"), "A")
                test.eq(#response.metadata.thinking_blocks, 0)
                for _, entry in ipairs(response.metadata.content_positions or {}) do
                    test.eq(entry.type, "text")
                end
            end)

            it("never replays thinking behind a discarded call: thinking, call: " .. path.name, function()
                local order, response = replay_after_truncation(path, { "s1", { "c1" } })
                test.eq(table.concat(order, "|"), "")
                test.eq(#response.metadata.thinking_blocks, 0)
            end)

            it("keeps thinking in front of the kept text: " .. path.name, function()
                local order = replay_after_truncation(path, { "s1", "A", "s2", { "c1" } })
                test.eq(table.concat(order, "|"), "s1|A")
            end)

            it("keeps a plain-order response's thinking in front of its text: " .. path.name, function()
                local order = replay_after_truncation(path, { "s1", "A", { "c1" } })
                test.eq(table.concat(order, "|"), "s1|A")
            end)
        end

        it("marks only what the host's predicate rejects", function()
            local sent = install({ id = "claude_route", provider_model = "wire" })
            local builder = handoff_history()
            assert(agent.new(spec("agent_b", 0)):step(builder, {
                drop_stale_thinking = true,
                thinking_is_current = function() return true end,
            }))
            test.is_true(claude_thinking(sent[1].payload.messages[2].content))
        end)

        it("marks nothing without drop_stale_thinking", function()
            local sent = install({ id = "claude_route", provider_model = "wire" })
            local builder = handoff_history()
            assert(agent.new(spec("agent_b", 0)):step(builder, {}))
            test.is_true(claude_thinking(sent[1].payload.messages[2].content))
        end)

        describe("prefix fingerprint", function()
            local function fingerprint(tool_meta, prompt_text)
                install({ id = "claude_route", provider_model = "wire" })
                local compiled = spec("agent_b", 0, prompt_text)
                compiled.tools.lookup.meta = tool_meta
                local builder = prompt.new()
                builder:add_user("q")
                return assert(agent.new(compiled):step(builder, {})).prefix_fingerprint
            end

            it("distinguishes schema arrays from objects while keeping equal schemas stable", function()
                local function schema_fingerprint(schema)
                    local sent = install({ id = "claude_route", provider_model = "wire" })
                    local compiled = spec("agent_b", 0)
                    compiled.tools.lookup.schema = schema
                    local builder = prompt.new()
                    builder:add_user("q")
                    local result = assert(agent.new(compiled):step(builder, {}))
                    return result.prefix_fingerprint, sent[1].payload.tools[1].input_schema
                end
                local array = { type = "object", properties = {}, enum = { "x" } }
                local object = { type = "object", properties = {}, enum = { ["1"] = "x" } }
                local array_fingerprint, array_wire = schema_fingerprint(array)
                local object_fingerprint, object_wire = schema_fingerprint(object)
                test.eq(json.encode(array_wire.enum), '["x"]')
                test.eq(json.encode(object_wire.enum), '{"1":"x"}')
                test.is_false(array_fingerprint == object_fingerprint, "different wire schemas need different fingerprints")
                local reordered = {}
                reordered.enum = { "x" }
                reordered.properties = {}
                reordered.type = "object"
                test.eq(schema_fingerprint(reordered), array_fingerprint, "key insertion order is irrelevant")
                test.eq(schema_fingerprint({ type = "object", properties = {}, enum = { "x" } }), array_fingerprint,
                    "equal schemas have equal fingerprints")
                test.eq(schema_fingerprint({ enum = { ["1"] = "x" }, properties = {}, type = "object" }), object_fingerprint)
            end)

            it("ignores meta.claude without a type, which never reaches the wire", function()
                test.eq(fingerprint({ claude = { display_width_px = 10 } }), fingerprint({}))
            end)

            it("ignores a meta.claude that is not a table", function()
                test.eq(fingerprint({ claude = "native" }), fingerprint({}))
            end)

            it("covers meta.claude with a type, which replaces the tool on the wire", function()
                test.is_false(fingerprint({ claude = { type = "computer_20251124" } }) == fingerprint({}))
                test.is_false(fingerprint({ claude = { type = "computer_20251124", display_width_px = 10 } })
                    == fingerprint({ claude = { type = "computer_20251124", display_width_px = 20 } }))
            end)

            it("ignores blank system text, which never reaches the wire", function()
                test.eq(fingerprint({}, ""), fingerprint({}, "  \n"))
            end)

            it("ignores a blank conversation system message", function()
                install({ id = "claude_route", provider_model = "wire" })
                local plain = prompt.new()
                plain:add_user("q")
                local with_blank = prompt.new({
                    { role = "system", content = text("  ") },
                    { role = "user", content = text("q") },
                })
                local compiled = agent.new(spec("agent_b", 0))
                test.eq(assert(compiled:step(with_blank, {})).prefix_fingerprint,
                    assert(compiled:step(plain, {})).prefix_fingerprint)
            end)
        end)
    end)
end

return test.run_cases(define_tests)
