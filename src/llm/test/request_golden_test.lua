local claude_mapper = require("claude_mapper")
local bedrock_mapper = require("bedrock_mapper")
local google_mapper = require("google_mapper")
local openai_mapper = require("openai_mapper")
local compat_mapper = require("compat_mapper")
local codec = require("codec")

-- Message-derived request body sections, recorded from the drivers before
-- positional notes existed. Prompts without positional notes must keep these
-- bytes exactly; any difference changes the provider prefix and its cache.
local GOLDEN = {
    claude = "{\"messages\":[{\"content\":[{\"text\":\"Hello\",\"type\":\"text\"}],\"role\":\"user\"},{\"content\":[{\"signature\":\"sig-greet\",\"thinking\":\"greet\",\"type\":\"thinking\"},{\"text\":\"Hi\",\"type\":\"text\"}],\"role\":\"assistant\"},{\"content\":[{\"text\":\"Look it up\\n\\u003cdeveloper-instruction\\u003ePrefer cached data\\u003c/developer-instruction\\u003e\",\"type\":\"text\"}],\"role\":\"user\"},{\"content\":[{\"signature\":\"sig-lookup\",\"thinking\":\"lookup\",\"type\":\"thinking\"},{\"id\":\"call_1\",\"input\":{\"q\":\"x\"},\"name\":\"lookup\",\"type\":\"tool_use\"}],\"role\":\"assistant\"},{\"content\":[{\"cache_control\":{\"type\":\"ephemeral\"},\"content\":\"found\",\"tool_use_id\":\"call_1\",\"type\":\"tool_result\"}],\"role\":\"user\"},{\"content\":[{\"text\":\"Answer briefly\",\"type\":\"text\"}],\"role\":\"user\"}],\"system\":[{\"cache_control\":{\"type\":\"ephemeral\"},\"text\":\"You are concise.\",\"type\":\"text\"},{\"text\":\"Mode: review\",\"type\":\"text\"}]}",
    bedrock = "{\"messages\":[{\"content\":[{\"text\":\"Hello\"}],\"role\":\"user\"},{\"content\":[{\"reasoningContent\":{\"reasoningText\":{\"signature\":\"sig-greet\",\"text\":\"greet\"}}},{\"text\":\"Hi\"}],\"role\":\"assistant\"},{\"content\":[{\"text\":\"Look it up\"}],\"role\":\"user\"},{\"content\":[{\"reasoningContent\":{\"reasoningText\":{\"signature\":\"sig-lookup\",\"text\":\"lookup\"}}},{\"toolUse\":{\"input\":{\"q\":\"x\"},\"name\":\"lookup\",\"toolUseId\":\"call_1\"}}],\"role\":\"assistant\"},{\"content\":[{\"toolResult\":{\"content\":[{\"text\":\"found\"}],\"status\":\"success\",\"toolUseId\":\"call_1\"}},{\"cachePoint\":{\"type\":\"default\"}}],\"role\":\"user\"}],\"system\":[{\"text\":\"You are concise.\"},{\"cachePoint\":{\"type\":\"default\"}},{\"text\":\"Mode: review\"}]}",
    google = "{\"contents\":[{\"parts\":[{\"text\":\"Hello\"}],\"role\":\"user\"},{\"parts\":[{\"text\":\"Hi\"}],\"role\":\"model\"},{\"parts\":[{\"text\":\"Look it up\"}],\"role\":\"user\"},{\"parts\":[{\"text\":\"Prefer cached data\"}],\"role\":\"user\"},{\"parts\":[{\"functionCall\":{\"args\":{\"q\":\"x\"},\"name\":\"lookup\"}}],\"role\":\"model\"},{\"parts\":[{\"functionResponse\":{\"name\":\"lookup\",\"response\":{\"content\":\"found\"}}}],\"role\":\"user\"},{\"parts\":[{\"text\":\"Answer briefly\"}],\"role\":\"user\"}],\"systemInstruction\":[{\"text\":\"You are concise.\"},{\"text\":\"Mode: review\"}]}",
    openai = "{\"input\":[{\"content\":[{\"text\":\"Hello\",\"type\":\"input_text\"}],\"role\":\"user\",\"type\":\"message\"},{\"content\":[{\"text\":\"Hi\",\"type\":\"output_text\"}],\"role\":\"assistant\",\"type\":\"message\"},{\"content\":[{\"text\":\"Look it up\",\"type\":\"input_text\"}],\"role\":\"user\",\"type\":\"message\"},{\"arguments\":\"{\\\"q\\\":\\\"x\\\"}\",\"call_id\":\"call_1\",\"name\":\"lookup\",\"type\":\"function_call\"},{\"call_id\":\"call_1\",\"output\":\"found\",\"type\":\"function_call_output\"}],\"instructions\":\"You are concise.\\n\\nPrefer cached data\\n\\nMode: review\\n\\nAnswer briefly\"}",
    openai_compat = "[{\"content\":[{\"text\":\"You are concise.\",\"type\":\"text\"}],\"role\":\"system\"},{\"content\":[{\"text\":\"Hello\",\"type\":\"text\"}],\"role\":\"user\"},{\"content\":\"Hi\",\"role\":\"assistant\"},{\"content\":[{\"text\":\"Look it up\",\"type\":\"text\"}],\"role\":\"user\"},{\"content\":[{\"text\":\"Prefer cached data\",\"type\":\"text\"}],\"role\":\"system\"},{\"content\":\"\",\"role\":\"assistant\",\"tool_calls\":[{\"function\":{\"arguments\":\"{\\\"q\\\":\\\"x\\\"}\",\"name\":\"lookup\"},\"id\":\"call_1\",\"type\":\"function\"}]},{\"content\":\"found\",\"name\":\"lookup\",\"role\":\"tool\",\"tool_call_id\":\"call_1\"},{\"content\":[{\"text\":\"Mode: review\",\"type\":\"text\"}],\"role\":\"system\"},{\"content\":[{\"text\":\"Answer briefly\",\"type\":\"text\"}],\"role\":\"system\"}]",
}

local function thinking(name)
    return { { type = "thinking", thinking = name, signature = "sig-" .. name } }
end

local function text(value)
    return { { type = "text", text = value } }
end

local function conversation(with_developer)
    local messages = {
        { role = "system", content = text("You are concise.") },
        { role = "cache_marker", marker_id = "agent" },
        { role = "user", content = text("Hello") },
        { role = "assistant", content = text("Hi"), metadata = { thinking_blocks = thinking("greet") } },
        { role = "user", content = text("Look it up") },
    }
    if with_developer then
        table.insert(messages, { role = "developer", content = text("Prefer cached data") })
    end
    table.insert(messages, {
        role = "function_call",
        content = {},
        function_call = { id = "call_1", name = "lookup", arguments = '{"q":"x"}' },
        metadata = { thinking_blocks = thinking("lookup") },
    })
    table.insert(messages, { role = "function_result", name = "lookup", function_call_id = "call_1", content = text("found") })
    table.insert(messages, { role = "cache_marker", marker_id = "conversation_tail" })
    table.insert(messages, { role = "system", content = text("Mode: review") })
    if with_developer then
        table.insert(messages, { role = "developer", content = text("Answer briefly") })
    end
    return messages
end

local function bodies()
    local google_contents, google_system = google_mapper.map_messages(conversation(true), { model = "gemini-2.5-pro" })
    return {
        claude = codec.canonical_json(claude_mapper.map_messages(conversation(true))),
        bedrock = codec.canonical_json(bedrock_mapper.map_messages(conversation(false))),
        google = codec.canonical_json({ contents = google_contents, systemInstruction = google_system }),
        openai = codec.canonical_json({
            instructions = openai_mapper.extract_instructions(conversation(true)),
            input = openai_mapper.map_messages(conversation(true), { model = "gpt-5" }),
        }),
        openai_compat = codec.canonical_json(compat_mapper.map_messages(conversation(true), { model = "gpt-5" })),
    }
end

local function define_tests()
    describe("Request body golden sections", function()
        for _, driver in ipairs({ "claude", "bedrock", "google", "openai", "openai_compat" }) do
            it("keeps the " .. driver .. " body byte-identical for prompts without positional notes", function()
                local body = bodies()[driver]
                test.not_nil(body)
                test.eq(body, GOLDEN[driver])
            end)
        end
    end)
end

return require("test").run_cases(define_tests)
