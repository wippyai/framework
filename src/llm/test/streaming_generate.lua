local store = require("store")
local time = require("time")
local output = require("output")

-- Streams the configured chunks; "hold" then keeps the call in flight like a slow provider.
local function handler(contract_args)
    local s, serr = store.get("app:test_store")
    if serr then return nil, errors.new({ message = "store error: " .. tostring(serr), kind = "Internal" }) end
    s:set("streaming_started", true)
    local scenario = s:get("streaming_scenario")
    local content = table.concat(scenario.chunks)
    if contract_args.stream and contract_args.stream.reply_to then
        local streamer, streamer_err = output.streamer(contract_args.stream.reply_to, contract_args.stream.topic, 0)
        if not streamer then return nil, errors.new({ message = tostring(streamer_err), kind = "Internal" }) end
        for _, chunk in ipairs(scenario.chunks) do
            streamer:send_content(chunk)
        end
    end
    if scenario.mode == "hold" then
        s:set("streaming_held", true)
        time.sleep("30s")
        s:set("streaming_resumed", true)
    end
    return {
        success = true,
        result = { content = content, tool_calls = {} },
        tokens = { prompt_tokens = 3, completion_tokens = #scenario.chunks, total_tokens = 3 + #scenario.chunks },
        finish_reason = "stop",
    }
end

return { handler = handler }
