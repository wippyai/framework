local test = require("test")
local json = require("json")
local llm = require("llm")
local prompt = require("prompt")
local agent = require("agent")
local claude_generate = require("claude_generate")
local bedrock_generate = require("bedrock_generate")

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
    local builder = prompt.new({ { role = "user", content = text("q1") }, answer })
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

local function define_tests()
    describe("Agent replay safety", function()
        after_each(function()
            llm._providers = nil
            llm._models = nil
            llm._usage_tracker = nil
            claude_generate._client = nil
            bedrock_generate._client = nil
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
