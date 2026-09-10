local time = require("time")

local broker = {}

local function wait_for_request(timeout_duration)
    local inbox = process.inbox()
    local timeout = time.after(timeout_duration or "5s")
    local selected = channel.select({
        inbox:case_receive(),
        timeout:case_receive(),
    })
    if not selected.ok then
        return nil, "broker inbox closed"
    end
    if selected.channel == timeout then
        return nil, "broker request timed out"
    end
    return selected.value, nil
end

function broker.run(args)
    if args.probe_receiver_pid then
        local topics = args.probe_topics or { "session_ui_action_result" }
        for index, topic in ipairs(topics) do
            local result_sent, result_err = process.send(args.probe_receiver_pid, topic, {
                schema = "wippy.ui-action.v1",
                message_type = "result",
                result_id = "result-route-probe-" .. index,
            })
            if not result_sent then
                return nil, result_err
            end
        end
        local noise_sent, noise_err = process.send(args.probe_receiver_pid, "ui_action_test_noise", {
            sender_pid = process.pid(),
        })
        if not noise_sent then
            return nil, noise_err
        end
        return true
    end

    local ready_sent, ready_err = process.send(args.reply_pid, "ui_action_test_broker_ready", {
        broker_pid = process.pid(),
    })
    if not ready_sent then
        return nil, ready_err
    end

    local request, request_err = wait_for_request("5s")
    if request_err then
        return nil, request_err
    end

    local sender_pid = request:from()
    local request_payload = request:payload()
    local request_data = request_payload:data()
    if request:topic() ~= "session_ui_action_request" then
        return nil, "unexpected request topic"
    end
    if type(request_data) ~= "table" then
        return nil, "unexpected request payload"
    end

    local result = {
        schema = "wippy.ui-action.v1",
        message_type = "result",
        result_id = "result-process-level",
        in_reply_to_action_id = "action-process-level",
        request_id = request_data.call_id,
        session_id = request_data.session_id,
        host_instance_id = request_data.host_instance_id,
        completed_at = "2026-09-04T12:00:00.000Z",
        status = "confirmed",
        selected_target = {
            target_id = "target-process-level",
        },
    }
    local sent, send_err = process.send(sender_pid, request_data.reply_topic, result)
    if not sent then
        return nil, send_err
    end

    if args.report_payload then
        process.send(args.reply_pid, "ui_action_test_audit", {
            broker_pid = process.pid(),
            requester_pid = sender_pid,
            request_payload_type = type(request_payload),
            request_call_id = request_data.call_id,
            request_reply_topic = request_data.reply_topic,
        })
    end
    if args.send_noise then
        process.send(args.reply_pid, "ui_action_test_noise", {
            broker_pid = process.pid(),
        })
    end
    return true
end

return broker
