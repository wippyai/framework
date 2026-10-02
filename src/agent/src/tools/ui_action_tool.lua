local ctx = require("ctx")
local time = require("time")

local ui_action_tool = {}

local RESULT_TOPIC_PREFIX = "session_ui_action_result:"
local VALID_STATUSES = {
    inspected = true,
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
        inspection = data.inspection,
        targets = data.targets,
        selected_target = data.selected_target,
        prepared_file = data.prepared_file,
        reason = data.reason,
    }
end

local function execute(mode, args, inspection_name)
    local all_context, context_err = ctx.all()
    if context_err or type(all_context) ~= "table" then
        return unavailable("runtime context is not available")
    end

    local runtime = all_context.ui_action_runtime
    if mode == "inspect" then runtime = all_context.attention_inspection_runtime end
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
        registry_id = inspection_name and "wippy.agent.tools:" .. inspection_name or TOOL_IDS[mode],
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
    local timeout = time.after(mode == "inspect" and "3s" or "121s")
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
            if inspection_name then
                return require("attention_read").project(result, inspection_name)
            end
            return result
        end
    end
end

function ui_action_tool.highlight(args)
    return execute("highlight", args)
end

local function inspect_named(name, args)
    local read = require("attention_read")
    local call, err = read.normalize(name, args)
    if not call then
        local receipt = read.receipt(err, "wippy.agent.tools:" .. name)
        receipt.invalid = true
        return receipt
    end
    return execute("inspect", call, name)
end

function ui_action_tool.attention_find_semantic(args) return inspect_named("attention_find_semantic", args) end
function ui_action_tool.attention_find_css(args) return inspect_named("attention_find_css", args) end
function ui_action_tool.attention_get_node(args) return inspect_named("attention_get_node", args) end
function ui_action_tool.attention_get_tree(args) return inspect_named("attention_get_tree", args) end
function ui_action_tool.attention_get_geometry(args) return inspect_named("attention_get_geometry", args) end
function ui_action_tool.attention_get_cursor(args) return inspect_named("attention_get_cursor", args) end
function ui_action_tool.attention_get_focus(args) return inspect_named("attention_get_focus", args) end
function ui_action_tool.attention_get_selection(args) return inspect_named("attention_get_selection", args) end
function ui_action_tool.attention_hit_test(args) return inspect_named("attention_hit_test", args) end

-- The guard keeps the refused call's own arguments for history and passes the
-- refusal in tool context. The arguments are never read here.
function ui_action_tool.attention_read_receipt(_args)
    local read = require("attention_read")
    local refusal = ctx.get("attention_refusal")
    if type(refusal) ~= "table" then refusal = {} end
    local allowed = { ["history-unavailable"]=true, ["read-budget-exhausted"]=true,
        ["repair-budget-exhausted"]=true, ["one-read-per-batch"]=true, ["duplicate-read"]=true }
    local reason = (allowed[refusal.reason] or read.validation_errors[refusal.reason]) and refusal.reason or "invalid-request"
    local id = read.is_read(refusal.original_registry_id) and refusal.original_registry_id or nil
    local receipt = read.receipt(reason, id)
    receipt.invalid = refusal.invalid == true
    return receipt
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
