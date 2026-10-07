local ctx = require("ctx")
local time = require("time")

local attention_context_tool = {}
local REQUEST_TOPIC = "session_attention_context_request"
local RESULT_TOPIC_PREFIX = "session_attention_context_result:"
local RESULT_SCHEMA = "wippy.attention.session-control.v1"

local function unavailable(message)
    return nil, "Attention context control unavailable: " .. message
end

local function result_topic(call_id)
    local digest, digest_err = hash.sha256(call_id)
    if not digest then
        return nil, digest_err or "call correlation hash failed"
    end
    return RESULT_TOPIC_PREFIX .. digest, nil
end

local function stop_listening(listener)
    if listener then
        process.unlisten(listener)
    end
end

function attention_context_tool.set(args)
    if type(args) ~= "table" or type(args.enabled) ~= "boolean" then
        return nil, "enabled must be a boolean"
    end
    if args.expected_revision ~= nil
        and (type(args.expected_revision) ~= "number"
            or args.expected_revision < 0
            or args.expected_revision % 1 ~= 0) then
        return nil, "expected_revision must be a non-negative integer"
    end

    local all_context, context_err = ctx.all()
    if context_err or type(all_context) ~= "table" then
        return unavailable("runtime context is not available")
    end
    local runtime = all_context.attention_context_runtime
    if type(runtime) ~= "table"
        or type(runtime.session_id) ~= "string"
        or runtime.session_id == ""
        or type(runtime.controller_pid) ~= "string"
        or runtime.controller_pid == ""
        or type(runtime.agent_id) ~= "string"
        or runtime.agent_id == ""
        or type(runtime.capability) ~= "string"
        or runtime.capability == ""
        or type(all_context.call_id) ~= "string"
        or all_context.call_id == "" then
        return unavailable("the current Session did not grant update authority")
    end

    local reply_topic, topic_err = result_topic(all_context.call_id)
    if not reply_topic then
        return unavailable("result topic failed: " .. tostring(topic_err))
    end
    local result_channel, listener_err = process.listen(reply_topic, { message = true })
    if not result_channel then
        return unavailable("result listener failed: " .. tostring(listener_err))
    end
    local sent, send_err = process.send(runtime.controller_pid, REQUEST_TOPIC, {
        request_id = all_context.call_id,
        reply_topic = reply_topic,
        session_id = runtime.session_id,
        agent_id = runtime.agent_id,
        capability = runtime.capability,
        enabled = args.enabled,
        expected_revision = args.expected_revision,
    })
    if not sent then
        stop_listening(result_channel)
        return unavailable("Session request failed: " .. tostring(send_err))
    end

    local timeout = time.after("10s")
    while true do
        local selected = channel.select({
            result_channel:case_receive(),
            timeout:case_receive(),
        })
        if not selected.ok then
            stop_listening(result_channel)
            return unavailable("result channel closed")
        end
        if selected.channel == timeout then
            stop_listening(result_channel)
            return unavailable("Session response timed out")
        end

        local message = selected.value
        local result = nil
        if message
            and message:topic() == reply_topic
            and tostring(message:from()) == runtime.controller_pid then
            local payload = message:payload()
            result = payload and payload:data() or nil
        end
        if result
            and result.schema == RESULT_SCHEMA
            and result.request_id == all_context.call_id
            and result.session_id == runtime.session_id then
            stop_listening(result_channel)
            if result.error then
                return nil, "Attention context update rejected: " .. tostring(result.error)
            end
            if type(result.attention_context) ~= "table" then
                return nil, "Attention context update rejected: invalid Session response"
            end
            return {
                session_id = runtime.session_id,
                attention_context = result.attention_context,
            }
        end
    end
end

return attention_context_tool
