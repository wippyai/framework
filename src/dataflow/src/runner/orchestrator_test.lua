local test = require("test")
local uuid = require("uuid")
local time = require("time")
local orchestrator = require("orchestrator")
local consts = require("consts")

local function define_tests()
    describe("Orchestrator", function()
        local mock_workflow_state
        local mock_scheduler
        local mock_process
        local mock_funcs

        before_each(function()
            -- Mock workflow state
            mock_workflow_state = {
                load_state = function(self) return self, nil end,
                get_nodes = function()
                    return {
                        ["node-1"] = {
                            type = "test_node",
                            status = consts.STATUS.PENDING,
                            parent_node_id = nil
                        }
                    }
                end,
                get_dataflow_metadata = function() return { test = "metadata" } end,
                get_scheduler_snapshot = function()
                    return {
                        nodes = {
                            ["node-1"] = {
                                type = "test_node",
                                status = consts.STATUS.PENDING
                            }
                        },
                        active_yields = {},
                        active_processes = {},
                        input_tracker = {
                            requirements = {},
                            available = { ["node-1"] = { input = true } }
                        },
                        has_workflow_output = false
                    }
                end,
                get_failed_node_errors = function() return nil end,
                track_process = function(self, node_id, pid) return self end,
                queue_commands = function(self, commands) return self end,
                persist = function(self) return { changes_made = true }, nil end,
                get_node = function(self, node_id)
                    return {
                        type = "test_node",
                        status = consts.STATUS.PENDING,
                        parent_node_id = nil
                    }
                end,
                handle_process_exit = function(self, pid, success, result) return nil end,
                process_commits = function(self, commit_ids) return { changes_made = false }, nil end,
                track_yield = function(self, node_id, yield_info) return self end,
                satisfy_yield = function(self, parent_id, results) return self end,
                has_workflow_output = false
            }

            -- Mock scheduler
            mock_scheduler = {
                find_next_work = function(snapshot)
                    return {
                        type = "complete_workflow",
                        payload = { success = true, message = "Test complete" }
                    }
                end,
                DECISION_TYPE = {
                    EXECUTE_NODES = "execute_nodes",
                    SATISFY_YIELD = "satisfy_yield",
                    COMPLETE_WORKFLOW = "complete_workflow",
                    NO_WORK = "no_work"
                }
            }

            -- Mock process - keep it simple for non-channel tests
            mock_process = {
                registry = {
                    register = function(name) end,
                    unregister = function(name) end
                },
                set_options = function(options) end,
                spawn_linked_monitored = function(node_type, host, args)
                    return "mock-pid-123", nil
                end,
                send = function(dest, topic, payload) end,
                terminate = function(pid) end,
                inbox = function()
                    return {
                        case_receive = function()
                            return { channel = "inbox", case = function() return false end }
                        end
                    }
                end,
                events = function()
                    return {
                        case_receive = function()
                            return { channel = "events", case = function() return false end }
                        end
                    }
                end,
                event = {
                    EXIT = "pid.exit",
                    LINK_DOWN = "pid.link.down",
                    CANCEL = "pid.cancel"
                }
            }

            -- Mock funcs
            mock_funcs = {
                new = function()
                    return {
                        call = function(self, func_id, args)
                            return { success = true }, nil
                        end
                    }
                end
            }

            -- Mock channel to exit immediately (no message processing)
            local mock_channel = {
                select = function(cases)
                    return { ok = false } -- Always exit immediately
                end
            }

            -- Replace global channel
            channel = mock_channel

            -- Replace orchestrator dependencies
            orchestrator.workflow_state = {
                new = function(dataflow_id) return mock_workflow_state, nil end
            }
            orchestrator.scheduler = mock_scheduler
            orchestrator.process = mock_process
            orchestrator.funcs = mock_funcs
        end)

        describe("Initialization", function()
            it("should fail with missing dataflow_id", function()
                local result = orchestrator.run({})

                expect(result.success).to_be_false()
                expect(result.error).to_contain("Missing required dataflow_id")
            end)

            it("should fail with nil args", function()
                local result = orchestrator.run(nil)

                expect(result.success).to_be_false()
                expect(result.error).to_contain("Missing required dataflow_id")
            end)

            it("should fail with empty string dataflow_id", function()
                local result = orchestrator.run({ dataflow_id = "" })

                expect(result.success).to_be_false()
                expect(result.error).to_contain("Missing required dataflow_id")
            end)

            it("should handle workflow state creation failure", function()
                orchestrator.workflow_state.new = function(dataflow_id)
                    return nil, "Failed to create workflow state"
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_false()
                expect(result.error).to_contain("Failed to create workflow state")
            end)

            it("should handle workflow state loading failure", function()
                mock_workflow_state.load_state = function(self)
                    return nil, "Failed to load state"
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_false()
                expect(result.error).to_contain("Failed to load workflow state")
            end)

            it("should handle empty workflow", function()
                mock_workflow_state.get_nodes = function() return {} end

                local result = orchestrator.run({ dataflow_id = "empty-workflow" })

                expect(result.success).to_be_true()
                expect(result.output.message).to_contain("Empty workflow")
                expect(result.dataflow_id).to_equal("empty-workflow")
            end)

            it("should call init function if provided", function()
                local init_called = false
                local init_args = nil

                mock_funcs.new = function()
                    return {
                        call = function(self, func_id, args)
                            init_called = true
                            init_args = args
                            return { success = true }, nil
                        end
                    }
                end

                local result = orchestrator.run({
                    dataflow_id = "test-workflow",
                    init_func_id = "app:test_init"
                })

                expect(result.success).to_be_true()
                expect(init_called).to_be_true()
                expect(init_args.dataflow_id).to_equal("test-workflow")
                expect(init_args.metadata).to_have_key("test")
            end)

            it("should continue if init function fails", function()
                mock_funcs.new = function()
                    return {
                        call = function(self, func_id, args)
                            return nil, "Init function failed"
                        end
                    }
                end

                local result = orchestrator.run({
                    dataflow_id = "test-workflow",
                    init_func_id = "app:failing_init"
                })

                expect(result.success).to_be_true() -- Should continue despite init failure
            end)
        end)

        describe("Node Execution", function()
            it("should execute node when scheduler returns execute_nodes", function()
                local spawn_calls = {}
                mock_process.spawn_linked_monitored = function(node_type, host, args)
                    table.insert(spawn_calls, { node_type = node_type, host = host, args = args })
                    return "test-pid", nil
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "execute_nodes",
                        payload = {
                            nodes = {
                                {
                                    node_id = "node-1",
                                    node_type = "test_node",
                                    path = {},
                                    trigger_reason = "root_ready"
                                }
                            }
                        }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_true()
                expect(#spawn_calls).to_equal(1)
                expect(spawn_calls[1].node_type).to_equal("test_node")
                expect(spawn_calls[1].host).to_equal(consts.HOST_ID)
                expect(spawn_calls[1].args.dataflow_id).to_equal("test-workflow")
                expect(spawn_calls[1].args.node_id).to_equal("node-1")
            end)

            it("should handle spawn failures", function()
                mock_process.spawn_linked_monitored = function()
                    return nil, "Spawn failed"
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "execute_nodes",
                        payload = {
                            nodes = {
                                {
                                    node_id = "node-1",
                                    node_type = "test_node",
                                    path = {},
                                    trigger_reason = "root_ready"
                                }
                            }
                        }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_false()
                expect(result.error).to_contain("Node spawn failures")
                expect(result.error).to_contain("node-1")
            end)

            it("should handle persist failures during execution", function()
                mock_workflow_state.persist = function(self)
                    return nil, "Persist failed"
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "execute_nodes",
                        payload = {
                            nodes = {
                                {
                                    node_id = "node-1",
                                    node_type = "test_node",
                                    path = {},
                                    trigger_reason = "root_ready"
                                }
                            }
                        }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_false()
                expect(result.error).to_contain("Failed to persist RUNNING status")
            end)

            it("should handle multiple nodes execution", function()
                local spawn_calls = {}
                mock_process.spawn_linked_monitored = function(node_type, host, args)
                    table.insert(spawn_calls, args.node_id)
                    return "test-pid-" .. args.node_id, nil
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "execute_nodes",
                        payload = {
                            nodes = {
                                {
                                    node_id = "node-1",
                                    node_type = "test_node",
                                    path = {},
                                    trigger_reason = "root_ready"
                                },
                                {
                                    node_id = "node-2",
                                    node_type = "test_node",
                                    path = {},
                                    trigger_reason = "root_ready"
                                }
                            }
                        }
                    }
                end

                mock_workflow_state.get_node = function(self, node_id)
                    return {
                        type = "test_node",
                        status = consts.STATUS.PENDING,
                        parent_node_id = nil
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_true()
                expect(#spawn_calls).to_equal(2)
                expect(spawn_calls).to_contain("node-1")
                expect(spawn_calls).to_contain("node-2")
            end)
        end)

        describe("Yield Handling", function()
            it("should handle yield satisfaction", function()
                local send_calls = {}
                mock_process.send = function(dest, topic, payload)
                    table.insert(send_calls, { dest = dest, topic = topic, payload = payload })
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "satisfy_yield",
                        payload = {
                            parent_id = "parent-1",
                            yield_id = "yield-123",
                            reply_to = "yield_reply",
                            results = { ["child-1"] = "result-data" }
                        }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_true()
            end)

            it("should handle persist failures during yield satisfaction", function()
                local persist_call_count = 0
                mock_workflow_state.persist = function(self)
                    persist_call_count = persist_call_count + 1
                    if persist_call_count == 1 then -- Succeed first time
                        return { changes_made = true }, nil
                    else -- Fail on yield satisfaction persist
                        return nil, "Persist failed"
                    end
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "satisfy_yield",
                        payload = {
                            parent_id = "parent-1",
                            yield_id = "yield-123",
                            reply_to = "yield_reply",
                            results = {}
                        }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_true() -- Should continue even if yield persist fails
            end)
        end)

        describe("Workflow Completion", function()
            it("should handle successful completion", function()
                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "complete_workflow",
                        payload = { success = true, message = "All nodes completed" }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_true()
                expect(result.output.message).to_equal("All nodes completed")
                expect(result.dataflow_id).to_equal("test-workflow")
                expect(result.error).to_be_nil()
            end)

            it("should handle failed completion with error details", function()
                mock_workflow_state.get_failed_node_errors = function()
                    return "Node [node-1] failed: Test error"
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "complete_workflow",
                        payload = { success = false, message = "Workflow deadlocked" }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_false()
                expect(result.error).to_contain("Node [node-1] failed: Test error")
                expect(result.dataflow_id).to_equal("test-workflow")
                expect(result.output).to_be_nil()
            end)

            it("should handle failed completion without specific errors", function()
                mock_workflow_state.get_failed_node_errors = function()
                    return nil
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "complete_workflow",
                        payload = { success = false, message = "Custom failure message" }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_false()
                expect(result.error).to_equal("Custom failure message")
            end)
        end)

        describe("Scheduler Integration", function()
            it("should handle NO_WORK decision", function()
                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "no_work",
                        payload = { message = "Waiting for events" }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_true() -- Should exit gracefully when no work
            end)

            it("should pass correct snapshot to scheduler", function()
                local snapshot_received = nil
                mock_scheduler.find_next_work = function(snapshot)
                    snapshot_received = snapshot
                    return {
                        type = "complete_workflow",
                        payload = { success = true, message = "Test" }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_true()
                expect(snapshot_received).not_to_be_nil()
                expect(snapshot_received.nodes).to_be_type("table")
                expect(snapshot_received.active_yields).to_be_type("table")
                expect(snapshot_received.active_processes).to_be_type("table")
                expect(snapshot_received.input_tracker).to_be_type("table")
                expect(snapshot_received.has_workflow_output).to_be_type("boolean")
            end)
        end)

        describe("Business Logic Tests", function()
            it("should properly handle different scheduler decision types", function()
                local decisions = {
                    { type = "no_work", expected_success = true },
                    { type = "complete_workflow", payload = { success = true, message = "Done" }, expected_success = true },
                    { type = "complete_workflow", payload = { success = false, message = "Failed" }, expected_success = false }
                }

                for _, decision in ipairs(decisions) do
                    mock_scheduler.find_next_work = function(snapshot)
                        return {
                            type = decision.type,
                            payload = decision.payload or {}
                        }
                    end

                    local result = orchestrator.run({ dataflow_id = "test-workflow-" .. decision.type })

                    expect(result.success).to_equal(decision.expected_success)
                    if decision.payload and decision.payload.message and decision.expected_success then
                        expect(result.output.message).to_equal(decision.payload.message)
                    end
                end
            end)

            it("should properly inject dependencies and call workflow state methods", function()
                local load_state_called = false
                local get_nodes_called = false
                local get_metadata_called = false
                local get_snapshot_called = false

                mock_workflow_state.load_state = function(self)
                    load_state_called = true
                    return self, nil
                end

                mock_workflow_state.get_nodes = function()
                    get_nodes_called = true
                    return { ["test-node"] = { type = "test", status = "pending" } }
                end

                mock_workflow_state.get_dataflow_metadata = function()
                    get_metadata_called = true
                    return { test = "data" }
                end

                mock_workflow_state.get_scheduler_snapshot = function()
                    get_snapshot_called = true
                    return {
                        nodes = {},
                        active_yields = {},
                        active_processes = {},
                        input_tracker = { requirements = {}, available = {} },
                        has_workflow_output = false
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_true()
                expect(load_state_called).to_be_true()
                expect(get_nodes_called).to_be_true()
                expect(get_snapshot_called).to_be_true()
            end)

            it("should handle workflow state method failures properly", function()
                -- Test load_state failure
                mock_workflow_state.load_state = function(self)
                    return nil, "Load failed"
                end

                local result1 = orchestrator.run({ dataflow_id = "test-workflow" })
                expect(result1.success).to_be_false()
                expect(result1.error).to_contain("Load failed")

                -- Test persist failure during node execution
                mock_workflow_state.load_state = function(self) return self, nil end
                mock_workflow_state.persist = function(self)
                    return nil, "Persist failed"
                end

                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "execute_nodes",
                        payload = {
                            nodes = {
                                {
                                    node_id = "test-node",
                                    node_type = "test_type",
                                    path = {},
                                    trigger_reason = "root_ready"
                                }
                            }
                        }
                    }
                end

                local result2 = orchestrator.run({ dataflow_id = "test-workflow" })
                expect(result2.success).to_be_false()
                expect(result2.error).to_contain("Persist failed")
            end)

            it("should maintain consistent error format", function()
                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "complete_workflow",
                        payload = { success = false, message = "Test failure" }
                    }
                end

                local result = orchestrator.run({ dataflow_id = "test-workflow" })

                expect(result.success).to_be_false()
                expect(result.error).to_be_type("string")
                expect(result.dataflow_id).to_equal("test-workflow")
                expect(result.output).to_be_nil()
            end)
        end)

        describe("Integration Points", function()
            it("should correctly setup process registry and options", function()
                local registry_calls = {}
                local options_calls = {}

                mock_process.registry.register = function(name)
                    table.insert(registry_calls, name)
                end

                mock_process.set_options = function(options)
                    table.insert(options_calls, options)
                end

                local result = orchestrator.run({ dataflow_id = "test-registry" })

                expect(result.success).to_be_true()
                expect(#registry_calls).to_equal(1)
                expect(registry_calls[1]).to_equal("dataflow.test-registry")
                expect(#options_calls).to_equal(1)
                expect(options_calls[1].trap_links).to_be_true()
            end)

            it("should properly format success and failure results", function()
                -- Test success case
                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "complete_workflow",
                        payload = { success = true, message = "Success result" }
                    }
                end

                local success_result = orchestrator.run({ dataflow_id = "success-test" })

                expect(success_result.success).to_be_true()
                expect(success_result.dataflow_id).to_equal("success-test")
                expect(success_result.output).not_to_be_nil()
                expect(success_result.output.message).to_equal("Success result")
                expect(success_result.error).to_be_nil()

                -- Test failure case
                mock_scheduler.find_next_work = function(snapshot)
                    return {
                        type = "complete_workflow",
                        payload = { success = false, message = "Failure result" }
                    }
                end

                local failure_result = orchestrator.run({ dataflow_id = "failure-test" })

                expect(failure_result.success).to_be_false()
                expect(failure_result.dataflow_id).to_equal("failure-test")
                expect(failure_result.error).to_equal("Failure result")
                expect(failure_result.output).to_be_nil()
            end)
        end)
    end)
end

return test.run_cases(define_tests)