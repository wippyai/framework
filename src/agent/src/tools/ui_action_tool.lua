local ctx = require("ctx")
local time = require("time")

local ui_action_tool = {}

local RESULT_TOPIC_PREFIX = "session_ui_action_result:"
local VALID_STATUSES = {
    cancelled = true,
    confirmed = true,
    denied = true,
    disconnected = true,
    error = true,
    expired = true,
    ["permission-denied"] = true,
    prepared = true,
    rejected = true,
    selected = true,
    stale = true,
    unavailable = true,
}

local TOOL_IDS = {
    highlight = "wippy.agent.tools:ui_action_highlight",
    confirm = "wippy.agent.tools:ui_action_confirm",
    capture_visual = "wippy.agent.tools:ui_action_capture_visual",
    select = "wippy.agent.tools:ui_action_select",
}

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

local function unavailable(message)
    return nil, "UI action unavailable: " .. message
end

local function result_payload(payload)
    local data = nil
    if type(payload) == "table" then
        data = payload
    elseif payload then
        data = payload:data()
    end
    if type(data) ~= "table" then
        return nil
    end
    return {
        schema = data.schema,
        message_type = data.message_type,
        result_id = data.result_id,
        in_reply_to_action_id = data.in_reply_to_action_id,
        request_id = data.request_id,
        session_id = data.session_id,
        host_instance_id = data.host_instance_id,
        completed_at = data.completed_at,
        status = data.status,
        selected_target = data.selected_target,
        prepared_file = data.prepared_file,
        reason = data.reason,
    }
end

local function execute(mode, args)
    local all_context, context_err = ctx.all()
    if context_err or type(all_context) ~= "table" then
        return unavailable("runtime context is not available")
    end

    local runtime = all_context.ui_action_runtime
    if type(runtime) ~= "table"
        or type(runtime.broker_pid) ~= "string"
        or type(runtime.delivery_handle) ~= "string"
        or type(runtime.session_id) ~= "string"
        or type(runtime.host_instance_id) ~= "string"
        or type(all_context.call_id) ~= "string" then
        return unavailable("agent actions were not enabled for this turn")
    end

    local reply_topic, topic_err = result_topic(all_context.call_id)
    if not reply_topic then
        return unavailable("result topic failed: " .. tostring(topic_err))
    end

    -- process.listen returns one stable channel per process/topic. A per-call
    -- topic prevents unrelated or overlapping tool waiters from competing for
    -- the same result while retaining broker Message metadata for authentication.
    local result_channel, listener_err = process.listen(reply_topic, { message = true })
    if not result_channel then
        return unavailable("result listener failed: " .. tostring(listener_err))
    end
    local sent, send_err = process.send(runtime.broker_pid, "session_ui_action_request", {
        delivery_handle = runtime.delivery_handle,
        registry_id = TOOL_IDS[mode],
        call_id = all_context.call_id,
        reply_topic = reply_topic,
        session_id = runtime.session_id,
        host_instance_id = runtime.host_instance_id,
        args = args or {},
    })
    if not sent then
        stop_listening(result_channel)
        return unavailable("broker request failed: " .. tostring(send_err))
    end
    local timeout = time.after("121s")
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
            process.send(runtime.broker_pid, "session_ui_action_cancel", {
                delivery_handle = runtime.delivery_handle,
                call_id = all_context.call_id,
            })
            stop_listening(result_channel)
            return unavailable("broker response timed out")
        end

        local message = selected.value
        local result = nil
        if message
            and message:topic() == reply_topic
            and tostring(message:from()) == runtime.broker_pid then
            result = result_payload(message:payload())
        end
        if result
            and result.schema == "wippy.ui-action.v1"
            and result.message_type == "result"
            and type(result.result_id) == "string"
            and result.result_id ~= ""
            and result.request_id == all_context.call_id
            and result.session_id == runtime.session_id
            and result.host_instance_id == runtime.host_instance_id
            and type(result.in_reply_to_action_id) == "string"
            and result.in_reply_to_action_id ~= ""
            and VALID_STATUSES[result.status] == true then
            stop_listening(result_channel)
            return result
        end
    end
end

function ui_action_tool.highlight(args)
    return execute("highlight", args)
end

function ui_action_tool.confirm(args)
    return execute("confirm", args)
end

function ui_action_tool.select(args)
    return execute("select", args)
end

function ui_action_tool.capture_visual(args)
    return execute("capture_visual", args)
end

ui_action_tool.TOOL_IDS = TOOL_IDS

return ui_action_tool
