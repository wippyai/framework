local funcs = require("funcs")
local json = require("json")
local time = require("time")
local test = require("test")

local function receive_with_timeout(receive_channel, timeout_duration)
    local timeout = time.after(timeout_duration or "5s")
    local selected = channel.select({
        receive_channel:case_receive(),
        timeout:case_receive(),
    })
    if selected.channel == timeout then
        return nil, "timed out"
    end
    if not selected.ok then
        return nil, "channel closed"
    end
    return selected.value, nil
end

local function start_broker(options)
    options = options or {}
    options.reply_pid = process.pid()
    local command = funcs.new():async("wippy.agent.tools:ui_action_test_broker", options)
    local ready_message, ready_err = receive_with_timeout(process.inbox(), "5s")
    test.is_nil(ready_err)
    test.not_nil(ready_message)
    test.eq(ready_message:topic(), "ui_action_test_broker_ready")
    local ready = ready_message:payload():data()
    test.eq(ready_message:from(), ready.broker_pid)
    return command, ready.broker_pid
end

local function define_tests()
    test.describe("Attention inspection tool process delivery", function()
        test.it("dispatches the exact specialized ID and returns only the compact result", function()
            local broker_command, broker_pid = start_broker({inspect=true, inspection_registry_id="wippy.agent.tools:attention_get_focus"})
            local result, err = funcs.new():with_context({call_id="explicit-focus",attention_inspection_runtime={
                broker_pid=broker_pid,delivery_handle="read",session_id="session",host_instance_id="host",
            }}):call("wippy.agent.tools:attention_get_focus", {})
            test.is_nil(err)
            test.eq(result.schema,"wippy.attention.model.v1")
            test.eq(result.status,"inspected")
            test.eq(result.outcome,"empty")
            test.is_nil(result.inspection)
            test.is_nil(result.session_id)
            test.is_true(#json.encode(result)<=8192)
            local response, response_err = receive_with_timeout(broker_command:response(), "5s")
            test.is_nil(response_err)
            test.not_nil(response)
        end)
        test.it("uses read-only runtime authority without interactive action authority", function()
            local broker_command, broker_pid = start_broker({
                inspect = true,
                inspection_registry_id = "wippy.agent.tools:attention_get_tree",
                inspection_operation = "tree",
            })
            local result, err = funcs.new():with_context({
                call_id = "call-inspection",
                attention_inspection_runtime = {
                    broker_pid = broker_pid, delivery_handle = "read-delivery",
                    session_id = "session-read", host_instance_id = "host-read",
                },
            }):call("wippy.agent.tools:attention_get_tree", {})
            test.is_nil(err)
            test.not_nil(result)
            test.eq(result.schema, "wippy.attention.model.v1")
            test.eq(result.status, "inspected")
            test.eq(result.outcome, "empty")
            test.is_nil(result.inspection)
            test.is_nil(result.targets)
            local response, response_err = receive_with_timeout(broker_command:response(), "5s")
            test.is_nil(response_err)
            test.not_nil(response)
        end)

        test.it("does not use interactive runtime as a substitute for inspection authority", function()
            local result, err = funcs.new():with_context({
                call_id = "call-no-read-authority",
                ui_action_runtime = {
                    broker_pid = "unused", delivery_handle = "unused",
                    session_id = "session-read", host_instance_id = "host-read",
                },
            }):call("wippy.agent.tools:attention_find_semantic", { name = "Save" })
            test.is_nil(result)
            test.not_nil(err)
        end)

        test.it("does not register the removed unrestricted attention_inspect tool", function()
            local result, err = funcs.new():with_context({
                call_id = "call-removed-inspect",
                attention_inspection_runtime = {
                    broker_pid = "unused", delivery_handle = "unused",
                    session_id = "session-read", host_instance_id = "host-read",
                },
            }):call("wippy.agent.tools:attention_inspect", { operation = "focus" })
            test.is_nil(result)
            test.not_nil(err)
        end)

        test.it("bounds a large UTF-8 inspection result to the compact model limit", function()
            local broker_command, broker_pid = start_broker({
                inspect = true, inspection_text = string.rep("😀", 10000),
                inspection_registry_id = "wippy.agent.tools:attention_get_tree",
                inspection_operation = "tree",
            })
            local result, err = funcs.new():with_context({
                call_id = "call-inspection-byte-limit",
                attention_inspection_runtime = {
                    broker_pid = broker_pid, delivery_handle = "read-delivery",
                    session_id = "session-read", host_instance_id = "host-read",
                },
            }):call("wippy.agent.tools:attention_get_tree", {})
            test.is_nil(err)
            test.not_nil(result)
            test.eq(result.status, "inspected")
            test.eq(result.outcome, "partial")
            test.eq(result.omissions[1].reason, "byte-limit")
            test.is_nil(result.nodes)
            test.is_nil(result.continuation)
            test.is_true(#json.encode(result) <= 8192)
            local response, response_err = receive_with_timeout(broker_command:response(), "5s")
            test.is_nil(response_err)
            test.not_nil(response)
        end)
    end)
    test.describe("UI action tool process delivery", function()
        test.it("unwraps a message-listener payload and authenticates the broker sender", function()
            local broker_command, broker_pid = start_broker({ report_payload = true })

            local executor = funcs.new():with_context({
                call_id = "call-process-level",
                ui_action_runtime = {
                    broker_pid = broker_pid,
                    delivery_handle = "delivery-process-level",
                    session_id = "session-process-level",
                    host_instance_id = "host-process-level",
                },
            })
            local command = executor:async("wippy.agent.tools:ui_action_highlight", {
                targets = {},
            })

            local response, response_err = receive_with_timeout(command:response(), "5s")
            if response_err then
                command:cancel()
            end
            test.is_nil(response_err)
            test.not_nil(response)

            local result_payload, result_err = command:result()
            test.is_nil(result_err)
            test.not_nil(result_payload)
            local result = result_payload:data()
            test.eq(result.status, "confirmed")
            test.eq(result.result_id, "result-process-level")
            test.eq(result.request_id, "call-process-level")
            test.eq(result.selected_target.target_id, "target-process-level")

            local audit_message, audit_err = receive_with_timeout(process.inbox(), "5s")
            test.is_nil(audit_err)
            test.not_nil(audit_message)
            test.eq(audit_message:topic(), "ui_action_test_audit")
            test.eq(audit_message:from(), broker_pid)
            test.eq(tostring(audit_message:from()), broker_pid)

            local audit_payload = audit_message:payload()
            test.eq(type(audit_payload), "userdata")
            local audit = audit_payload:data()
            test.eq(audit.broker_pid, broker_pid)
            test.eq(audit.request_call_id, "call-process-level")
            test.eq(audit.request_payload_type, "userdata")
            test.eq(
                audit.request_reply_topic,
                "session_ui_action_result:" .. hash.sha256("call-process-level")
            )
            test.eq(#audit.request_reply_topic, 89)
            local broker_response, broker_response_err = receive_with_timeout(broker_command:response(), "5s")
            test.is_nil(broker_response_err)
            test.not_nil(broker_response)
        end)

        test.it("returns one competing channel for repeated same-topic listeners", function()
            local first, first_err = process.listen("session_ui_action_result", { message = true })
            local second, second_err = process.listen("session_ui_action_result", { message = true })
            test.is_nil(first_err)
            test.is_nil(second_err)
            test.not_nil(first)
            test.eq(first, second)
            test.is_true((process.unlisten(first)))
        end)

        test.it("isolates per-call result listeners while the default inbox is contended", function()
            local first_topic = "session_ui_action_result:" .. hash.sha256("call-route-one")
            local second_topic = "session_ui_action_result:" .. hash.sha256("call-route-two")
            local first_channel, first_err = process.listen(first_topic, { message = true })
            local second_channel, second_err = process.listen(second_topic, { message = true })
            test.is_nil(first_err)
            test.is_nil(second_err)
            test.not_nil(first_channel)
            test.not_nil(second_channel)
            test.is_false(first_channel == second_channel)

            local contended = channel.new(1)
            coroutine.spawn(function()
                local message, ok = process.inbox():receive()
                if ok then
                    contended:send(message)
                end
            end)

            local sender_command = funcs.new():async("wippy.agent.tools:ui_action_test_broker", {
                probe_receiver_pid = process.pid(),
                probe_topics = { first_topic, second_topic },
            })
            local first_message, first_receive_err = receive_with_timeout(first_channel, "5s")
            local second_message, second_receive_err = receive_with_timeout(second_channel, "5s")
            test.is_nil(first_receive_err)
            test.is_nil(second_receive_err)
            test.not_nil(first_message)
            test.not_nil(second_message)
            test.eq(first_message:topic(), first_topic)
            test.eq(second_message:topic(), second_topic)
            test.eq(first_message:payload():data().result_id, "result-route-probe-1")
            test.eq(second_message:payload():data().result_id, "result-route-probe-2")

            local noise_message, noise_err = receive_with_timeout(contended, "5s")
            test.is_nil(noise_err)
            test.not_nil(noise_message)
            test.eq(noise_message:topic(), "ui_action_test_noise")
            test.eq(first_message:from(), noise_message:from())
            test.eq(second_message:from(), noise_message:from())
            test.is_true((process.unlisten(first_channel)))
            test.is_true((process.unlisten(second_channel)))
            local sender_response, sender_response_err = receive_with_timeout(sender_command:response(), "5s")
            test.is_nil(sender_response_err)
            test.not_nil(sender_response)
        end)

        test.it("routes results to a message listener while the default inbox is contended", function()
            local broker_command, broker_pid = start_broker({ send_noise = true })
            local contended = channel.new(1)
            coroutine.spawn(function()
                local message, ok = process.inbox():receive()
                if ok then
                    contended:send(message)
                end
            end)

            local result, call_err = funcs.new():with_context({
                call_id = "call-sync-process-level",
                ui_action_runtime = {
                    broker_pid = broker_pid,
                    delivery_handle = "delivery-sync-process-level",
                    session_id = "session-sync-process-level",
                    host_instance_id = "host-sync-process-level",
                },
            }):call("wippy.agent.tools:ui_action_highlight", {
                targets = {},
            })
            test.is_nil(call_err)
            test.not_nil(result)
            test.eq(result.status, "confirmed")
            test.eq(result.request_id, "call-sync-process-level")

            local noise_message, noise_err = receive_with_timeout(contended, "5s")
            test.is_nil(noise_err)
            test.not_nil(noise_message)
            test.eq(noise_message:topic(), "ui_action_test_noise")
            test.eq(noise_message:from(), broker_pid)
            local broker_response, broker_response_err = receive_with_timeout(broker_command:response(), "5s")
            test.is_nil(broker_response_err)
            test.not_nil(broker_response)
        end)
    end)
end

return { run_tests = test.run_cases(define_tests) }
