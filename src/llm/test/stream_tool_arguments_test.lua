local test = require("test")
local json = require("json")

-- One get_weather call whose argument text arrives in two deltas.
local ARGUMENT_PARTS = { '{"location": "Tokyo",', ' "unit": null}' }
local ARGUMENTS = table.concat(ARGUMENT_PARTS)
local MALFORMED = '{"location": "Tok'

local TOOLS = {
    {
        name = "get_weather",
        description = "Current weather",
        schema = { type = "object", properties = { location = { type = "string" }, unit = { type = "string" } } }
    }
}

local function sse(data: any): string
    return "data: " .. json.encode(data) .. "\n\n"
end

local function claude_event(name: string, data: any): string
    return "event: " .. name .. "\ndata: " .. json.encode(data) .. "\n\n"
end

-- Eventstream message with zeroed CRCs; the client does not verify them.
local function bedrock_event(event_type: string, body: any): string
    local function header(name: string, value: string): string
        return string.char(#name) .. name .. string.char(7) .. string.pack(">I2", #value) .. value
    end
    local headers = header(":event-type", event_type) .. header(":content-type", "application/json")
        .. header(":message-type", "event")
    local payload = json.encode(body)
    return string.pack(">I4I4I4", 12 + #headers + #payload + 4, #headers, 0) .. headers .. payload .. string.pack(">I4", 0)
end

local STREAMS = {
    openai = function(parts: {string}): {string}
        local events = {
            sse({ type = "response.output_item.added", output_index = 0,
                item = { type = "function_call", id = "fc_1", call_id = "call_1", name = "get_weather", arguments = "" } }),
        }
        for _, part in ipairs(parts) do
            table.insert(events, sse({ type = "response.function_call_arguments.delta", item_id = "fc_1",
                output_index = 0, delta = part }))
        end
        table.insert(events, sse({ type = "response.function_call_arguments.done", item_id = "fc_1",
            output_index = 0, name = "get_weather", arguments = table.concat(parts) }))
        table.insert(events, sse({ type = "response.completed",
            response = { id = "r1", status = "completed", usage = { input_tokens = 5, output_tokens = 9 } } }))
        return events
    end,
    openai_compat = function(parts: {string}): {string}
        local events = {
            sse({ choices = { { delta = { tool_calls = { { index = 0, id = "call_1", type = "function",
                ["function"] = { name = "get_weather" } } } } } } }),
        }
        for _, part in ipairs(parts) do
            table.insert(events, sse({ choices = { { delta = { tool_calls = { { index = 0,
                ["function"] = { arguments = part } } } } } } }))
        end
        table.insert(events, sse({ choices = { { delta = {}, finish_reason = "tool_calls" } } }))
        table.insert(events, "data: [DONE]\n\n")
        return events
    end,
    claude = function(parts: {string}): {string}
        local events = {
            claude_event("message_start", { type = "message_start", message = { id = "msg_1", type = "message",
                role = "assistant", content = {}, usage = { input_tokens = 5, output_tokens = 1 } } }),
            claude_event("content_block_start", { type = "content_block_start", index = 0,
                content_block = { type = "tool_use", id = "toolu_1", name = "get_weather" } }),
        }
        for _, part in ipairs(parts) do
            table.insert(events, claude_event("content_block_delta", { type = "content_block_delta", index = 0,
                delta = { type = "input_json_delta", partial_json = part } }))
        end
        table.insert(events, claude_event("content_block_stop", { type = "content_block_stop", index = 0 }))
        table.insert(events, claude_event("message_delta", { type = "message_delta",
            delta = { stop_reason = "tool_use" }, usage = { output_tokens = 9 } }))
        table.insert(events, claude_event("message_stop", { type = "message_stop" }))
        return events
    end,
    bedrock = function(parts: {string}): {string}
        local events = {
            bedrock_event("messageStart", { role = "assistant" }),
            bedrock_event("contentBlockStart", { contentBlockIndex = 0,
                start = { toolUse = { toolUseId = "tooluse_1", name = "get_weather" } } }),
        }
        for _, part in ipairs(parts) do
            table.insert(events, bedrock_event("contentBlockDelta", { contentBlockIndex = 0,
                delta = { toolUse = { input = part } } }))
        end
        table.insert(events, bedrock_event("contentBlockStop", { contentBlockIndex = 0 }))
        table.insert(events, bedrock_event("messageStop", { stopReason = "tool_use" }))
        table.insert(events, bedrock_event("metadata", { usage = { inputTokens = 5, outputTokens = 9 } }))
        return events
    end
}

local DRIVERS = {
    { name = "openai", handler = require("openai_generate") },
    { name = "openai_compat", handler = require("compat_generate") },
    { name = "claude", handler = require("claude_generate") },
    { name = "bedrock", handler = require("bedrock_generate") },
}

local function stream_of(events: {string})
    local reads = 0
    return {
        read = function(_self, _size)
            reads = reads + 1
            return events[reads]
        end
    }
end

local function sent_chunks(): {any}
    local chunks = {}
    mock("process.send", function(_pid, _topic, chunk)
        table.insert(chunks, chunk)
        return true
    end)
    return chunks
end

local function tool_call_chunks(chunks: {any}): {any}
    local calls = {}
    for _, chunk in ipairs(chunks) do
        if type(chunk) == "table" and chunk.type == "tool_call" then
            table.insert(calls, chunk)
        end
    end
    return calls
end

-- Serves `events` to a driver's generate handler as its provider's streamed response.
local function generate(driver: any, events: {string}): (any, any)
    local client = driver.handler._client
    local saved = {}
    for _, name in ipairs({ "_ctx", "_env", "_http_client", "_credentials", "_sigv4" }) do
        saved[name] = client[name]
    end
    client._ctx = { all = function() return { api_key = "test-key" } end }
    client._env = { get = function() return nil end }
    client._http_client = { post = function()
        return { status_code = 200, headers = {}, stream = stream_of(events) }
    end }
    if driver.name == "bedrock" then
        client._credentials = { resolve = function()
            return { access_key = "AKIDEXAMPLE", secret_key = "signing-key" }
        end }
        client._sigv4 = { sign_request = function(request) return request.headers end }
    end

    local response, err = driver.handler.handler({
        model = "test-model",
        messages = { { role = "user", content = { { type = "text", text = "Weather in Tokyo?" } } } },
        tools = TOOLS,
        stream = { reply_to = "stream-pid", topic = "stream-topic" }
    })

    for name, value in pairs(saved) do
        client[name] = value
    end
    return response, err
end

local function define_tests()
    describe("Streamed tool call arguments", function()
        for _, driver in ipairs(DRIVERS) do
            it(driver.name .. " streams the argument JSON text and returns the decoded call", function()
                local chunks = sent_chunks()

                local response, err = generate(driver, STREAMS[driver.name](ARGUMENT_PARTS))

                test.is_nil(err)
                local calls = tool_call_chunks(chunks)
                test.eq(#calls, 1)
                test.eq(calls[1].name, "get_weather")
                test.eq(calls[1].arguments, ARGUMENTS)

                local call = response.result.tool_calls[1]
                test.eq(call.name, "get_weather")
                test.eq(call.id, calls[1].id)
                test.is_table(call.arguments)
                test.eq(call.arguments.location, "Tokyo")
                test.is_nil(call.raw_arguments)
                test.is_nil(call.arguments_error)
            end)

            it(driver.name .. " streams malformed argument text as received", function()
                local chunks = sent_chunks()

                local response, err = generate(driver, STREAMS[driver.name]({ MALFORMED }))

                test.is_nil(err)
                local calls = tool_call_chunks(chunks)
                test.eq(#calls, 1)
                test.eq(calls[1].arguments, MALFORMED)

                local call = response.result.tool_calls[1]
                test.eq(call.arguments, MALFORMED)
                test.eq(call.raw_arguments, MALFORMED)
                test.is_string(call.arguments_error)
            end)

            if driver.name == "claude" or driver.name == "bedrock" then
                it(driver.name .. " streams an empty object for a call without input deltas", function()
                    local chunks = sent_chunks()

                    local response, err = generate(driver, STREAMS[driver.name]({}))

                    test.is_nil(err)
                    local calls = tool_call_chunks(chunks)
                    test.eq(#calls, 1)
                    test.eq(calls[1].arguments, "{}")
                    test.is_nil(response.result.tool_calls[1].arguments_error)
                end)
            end
        end

        it("google streams the argument JSON text of a functionCall", function()
            local chunks = sent_chunks()
            local client = require("google_client")
            local saved = client._http_client
            client._http_client = { post = function()
                return { status_code = 200, headers = {}, stream = stream_of({
                    sse({ candidates = { { content = { parts = { { functionCall = {
                        name = "get_weather", args = { location = "Tokyo" } } } } }, finishReason = "STOP" } } })
                }) }
            end }

            local _, err = client.request("POST", "https://generativelanguage.example.test/v1/generate", {
                headers = {}, body = "{}", stream = true, stream_reply_to = "stream-pid", stream_topic = "stream-topic"
            })
            client._http_client = saved

            test.is_nil(err)
            local calls = tool_call_chunks(chunks)
            test.eq(#calls, 1)
            test.is_string(calls[1].arguments)
            test.eq(json.decode(calls[1].arguments).location, "Tokyo")
        end)
    end)
end

return test.run_cases(define_tests)
