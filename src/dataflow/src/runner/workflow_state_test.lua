local test = require("test")
local uuid = require("uuid")
local time = require("time")
local sql = require("sql")
local workflow_state = require("workflow_state")
local consts = require("consts")

local function define_tests()
    describe("WorkflowState", function()
        local test_ctx = {
            db = nil,
            tx = nil,
            dataflow_id = nil,
            actor_id = nil
        }

        before_each(function()
            -- Setup database connection
            local db, err_db = sql.get("app:db")
            if err_db then error("Failed to connect to database: " .. err_db) end
            test_ctx.db = db

            local tx, err_tx = db:begin()
            if err_tx then
                db:release()
                error("Failed to begin transaction: " .. err_tx)
            end
            test_ctx.tx = tx

            -- Create test dataflow
            test_ctx.dataflow_id = uuid.v7()
            test_ctx.actor_id = "test-actor-" .. uuid.v7()
            local now_ts = time.now():format(time.RFC3339NANO)

            local _, err_create = tx:execute([[
                INSERT INTO dataflows (
                    dataflow_id, actor_id, type, status, metadata, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ]], {
                test_ctx.dataflow_id,
                test_ctx.actor_id,
                "test_workflow",
                "active",
                "{}",
                now_ts,
                now_ts
            })

            if err_create then
                tx:rollback()
                db:release()
                error("Failed to create test dataflow: " .. err_create)
            end
        end)

        after_each(function()
            if test_ctx.tx then
                test_ctx.tx:rollback()
                test_ctx.tx = nil
            end

            if test_ctx.db then
                test_ctx.db:release()
                test_ctx.db = nil
            end

            test_ctx.dataflow_id = nil
            test_ctx.actor_id = nil
        end)

        -- Helper to create test nodes
        local function create_test_nodes(tx, dataflow_id, nodes)
            for _, node in ipairs(nodes) do
                local now_ts = time.now():format(time.RFC3339NANO)
                local parent_id = node.parent_node_id
                if parent_id == "" then
                    parent_id = nil
                end

                local _, err = tx:execute([[
                    INSERT INTO nodes (
                        node_id, dataflow_id, parent_node_id, type, status, metadata, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ]], {
                    node.node_id,
                    dataflow_id,
                    parent_id,
                    node.type,
                    node.status or consts.STATUS.PENDING,
                    "{}",
                    now_ts,
                    now_ts
                })
                if err then
                    error("Failed to create test node: " .. err)
                end
            end
        end

        -- Helper to create test data
        local function create_test_data(tx, dataflow_id, data_records)
            for _, data in ipairs(data_records) do
                local now_ts = time.now():format(time.RFC3339NANO)
                local _, err = tx:execute([[
                    INSERT INTO data (
                        data_id, dataflow_id, node_id, type, discriminator, key, content, content_type, metadata, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ]], {
                    data.data_id or uuid.v7(),
                    dataflow_id,
                    data.node_id,
                    data.type,
                    data.discriminator,
                    data.key,
                    data.content or "",
                    data.content_type or "application/json",
                    data.metadata or "{}",
                    now_ts
                })
                if err then
                    error("Failed to create test data: " .. err)
                end
            end
        end

        describe("Constructor", function()
            it("should create a new workflow state instance", function()
                local ws, err = workflow_state.new(test_ctx.dataflow_id)

                expect(err).to_be_nil()
                expect(ws).not_to_be_nil()
                expect(ws.dataflow_id).to_equal(test_ctx.dataflow_id)
                expect(ws.loaded).to_be_false()
                expect(type(ws.nodes)).to_equal("table")
                expect(type(ws.active_processes)).to_equal("table")
                expect(type(ws.active_yields)).to_equal("table")
                expect(ws.has_workflow_output).to_be_false()
                expect(type(ws.queued_commands)).to_equal("table")
                expect(#ws.queued_commands).to_equal(0)
            end)

            it("should fail with missing dataflow_id", function()
                local ws, err = workflow_state.new(nil)

                expect(ws).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Dataflow ID is required")
            end)

            it("should fail with empty dataflow_id", function()
                local ws, err = workflow_state.new("")

                expect(ws).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Dataflow ID is required")
            end)
        end)

        describe("State Loading", function()
            it("should load dataflow and nodes from database", function()
                -- Create test nodes with unique IDs
                local node1_id = "node-" .. uuid.v7()
                local node2_id = "node-" .. uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = node1_id,
                        type = "test_node",
                        parent_node_id = nil
                    },
                    {
                        node_id = node2_id,
                        type = "child_node",
                        parent_node_id = node1_id
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()
                expect(ws).not_to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()
                expect(result).not_to_be_nil()

                expect(ws.loaded).to_be_true()
                expect(ws.nodes[node1_id]).not_to_be_nil()
                expect(ws.nodes[node1_id].type).to_equal("test_node")
                expect(ws.nodes[node2_id]).not_to_be_nil()
                expect(ws.nodes[node2_id].parent_node_id).to_equal(node1_id)
            end)

            it("should detect existing workflow output", function()
                -- Create workflow output data
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                        content = '{"result": "test"}'
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()
                expect(result).not_to_be_nil()

                expect(ws.has_workflow_output).to_be_true()
            end)

            it("should reset RUNNING nodes to PENDING on recovery", function()
                -- Create a running node with unique ID
                local running_node_id = "running-node-" .. uuid.v7()
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = running_node_id,
                        type = "test_node",
                        status = consts.STATUS.RUNNING
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()
                expect(result).not_to_be_nil()

                expect(ws.nodes[running_node_id].status).to_equal(consts.STATUS.PENDING)
            end)

            it("should load existing node inputs", function()
                -- Create test node and input data
                local node_id = "input-node-" .. uuid.v7()
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = node_id,
                        type = "test_node"
                    }
                })

                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = node_id,
                        type = consts.DATA_TYPE.NODE_INPUT,
                        key = "config",
                        content = '{"value": "test"}'
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                -- Set input requirements
                ws:set_input_requirements(node_id, {
                    required = { "config" },
                    optional = {}
                })

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()
                expect(result).not_to_be_nil()

                expect(ws.input_tracker.available[node_id]).not_to_be_nil()
                expect(ws.input_tracker.available[node_id]["config"]).to_be_true()
            end)
        end)

        describe("Error Query", function()
            it("should return nil when no nodes have failed", function()
                -- Commit test transaction to avoid conflicts
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                local error_summary = ws:get_failed_node_errors()
                expect(error_summary).to_be_nil()
            end)

            it("should return formatted error details for failed nodes with simple string content", function()
                local failed_node_id = uuid.v7()

                -- Create failed node
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = "test_node",
                        status = consts.STATUS.COMPLETED_FAILURE
                    }
                })

                -- Create error result data with simple string content
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.error",
                        content = "Function 'test_func' not found",
                        content_type = "text/plain"
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                local error_summary = ws:get_failed_node_errors()
                expect(error_summary).not_to_be_nil()
                expect(error_summary).to_contain("Node [" .. failed_node_id .. "] failed")
                expect(error_summary).to_contain("Function 'test_func' not found")
                expect(string.find(error_summary, "{", 1, true)).to_be_nil() -- Should not contain JSON brackets
            end)

            it("should extract error.message from JSON error content", function()
                local failed_node_id = uuid.v7()

                -- Create failed node
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = "test_node",
                        status = consts.STATUS.COMPLETED_FAILURE
                    }
                })

                -- Create error result data with structured JSON error (like from integration test)
                local error_json = '{"success":false,"message":"Missing func_id in node config","error":{"code":"MISSING_FUNC_ID","message":"Function ID not specified in node configuration"},"data_ids":[]}'
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.error",
                        content = error_json,
                        content_type = "application/json"
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                local error_summary = ws:get_failed_node_errors()
                expect(error_summary).not_to_be_nil()
                expect(error_summary).to_contain("Node [" .. failed_node_id .. "] failed")
                -- Should extract the specific error.message
                expect(error_summary).to_contain("Function ID not specified in node configuration")
                -- Should NOT contain the raw JSON
                expect(string.find(error_summary, '{"success"', 1, true)).to_be_nil()
                expect(string.find(error_summary, '"data_ids"', 1, true)).to_be_nil()
            end)

            it("should extract top-level message from JSON when error.message not available", function()
                local failed_node_id = uuid.v7()

                -- Create failed node
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = "test_node",
                        status = consts.STATUS.COMPLETED_FAILURE
                    }
                })

                -- Create error result data with JSON that has message but no error.message
                local error_json = '{"success":false,"message":"Configuration validation failed","details":"Missing required field"}'
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.error",
                        content = error_json,
                        content_type = "application/json"
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                local error_summary = ws:get_failed_node_errors()
                expect(error_summary).not_to_be_nil()
                expect(error_summary).to_contain("Node [" .. failed_node_id .. "] failed")
                -- Should extract the top-level message
                expect(error_summary).to_contain("Configuration validation failed")
                -- Should NOT contain raw JSON
                expect(string.find(error_summary, '{"success"', 1, true)).to_be_nil()
            end)

            it("should fall back to raw content for JSON without meaningful message", function()
                local failed_node_id = uuid.v7()

                -- Create failed node
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = "test_node",
                        status = consts.STATUS.COMPLETED_FAILURE
                    }
                })

                -- Create error result data with JSON that has no meaningful message fields
                local error_json = '{"code":500,"details":["field1","field2"]}'
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.error",
                        content = error_json,
                        content_type = "application/json"
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                local error_summary = ws:get_failed_node_errors()
                expect(error_summary).not_to_be_nil()
                expect(error_summary).to_contain("Node [" .. failed_node_id .. "] failed")
                -- Should fall back to raw JSON content since no message fields
                expect(error_summary).to_contain(error_json)
            end)

            it("should handle malformed JSON gracefully", function()
                local failed_node_id = uuid.v7()

                -- Create failed node
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = "test_node",
                        status = consts.STATUS.COMPLETED_FAILURE
                    }
                })

                -- Create error result data with malformed JSON
                local malformed_json = '{"success":false,"message":"Incomplete JSON'
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.error",
                        content = malformed_json,
                        content_type = "application/json"
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                local error_summary = ws:get_failed_node_errors()
                expect(error_summary).not_to_be_nil()
                expect(error_summary).to_contain("Node [" .. failed_node_id .. "] failed")
                -- Should fall back to raw content when JSON parsing fails
                expect(error_summary).to_contain(malformed_json)
            end)

            it("should handle multiple failed nodes", function()
                local failed_node1_id = uuid.v7()
                local failed_node2_id = uuid.v7()

                -- Create failed nodes
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node1_id,
                        type = "test_node",
                        status = consts.STATUS.COMPLETED_FAILURE
                    },
                    {
                        node_id = failed_node2_id,
                        type = "test_node",
                        status = consts.STATUS.COMPLETED_FAILURE
                    }
                })

                -- Create error result data - mix of JSON and string
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node1_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.error",
                        content = '{"error":{"message":"First JSON error"}}',
                        content_type = "application/json"
                    },
                    {
                        node_id = failed_node2_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.error",
                        content = "Second string error",
                        content_type = "text/plain"
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                local error_summary = ws:get_failed_node_errors()
                expect(error_summary).not_to_be_nil()
                expect(error_summary).to_contain("Node [" .. failed_node1_id .. "] failed")
                expect(error_summary).to_contain("Node [" .. failed_node2_id .. "] failed")
                expect(error_summary).to_contain("First JSON error")
                expect(error_summary).to_contain("Second string error")
                expect(error_summary).to_contain(";") -- Multiple errors separated by semicolon
            end)

            it("should handle failed nodes without error data", function()
                local failed_node_id = uuid.v7()

                -- Create failed node without error result data
                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = failed_node_id,
                        type = "test_node",
                        status = consts.STATUS.COMPLETED_FAILURE
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                local error_summary = ws:get_failed_node_errors()
                expect(error_summary).not_to_be_nil()
                expect(error_summary).to_contain("Node [" .. failed_node_id .. "] failed")
                expect(error_summary).to_contain("Unknown error")
            end)
        end)

        describe("Scheduler Snapshot", function()
            it("should provide consistent state snapshot for scheduler", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                -- Set up some state
                ws.nodes["node-1"] = {
                    status = consts.STATUS.PENDING,
                    type = "test_node"
                }
                ws:track_process("node-1", "pid-123")
                ws:set_input_requirements("node-1", {
                    required = { "config" },
                    optional = {}
                })

                local snapshot = ws:get_scheduler_snapshot()

                expect(snapshot.nodes["node-1"]).not_to_be_nil()
                expect(snapshot.active_processes["node-1"]).to_be_true()
                expect(snapshot.input_tracker.requirements["node-1"]).not_to_be_nil()
                expect(snapshot.has_workflow_output).to_be_false()
            end)
        end)

        describe("Process Tracking", function()
            it("should track and untrack processes", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws:track_process("node-1", "pid-123")

                expect(ws.active_processes["node-1"]).to_equal("pid-123")
                expect(ws:is_node_active("node-1")).to_be_true()
            end)

            it("should handle process exits", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws.nodes["node-1"] = {
                    status = consts.STATUS.RUNNING,
                    type = "test_node"
                }
                ws:track_process("node-1", "pid-123")

                local exit_info = ws:handle_process_exit("pid-123", true, "success result")

                expect(exit_info.node_id).to_equal("node-1")
                expect(exit_info.success).to_be_true()
                expect(ws.active_processes["node-1"]).to_be_nil()
                expect(ws.nodes["node-1"].status).to_equal(consts.STATUS.COMPLETED_SUCCESS)
                expect(#ws.queued_commands).to_be_greater_than(0)
            end)

            it("should handle process exit for unknown PID", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local exit_info = ws:handle_process_exit("unknown-pid", true, "result")

                expect(exit_info).to_be_nil()
            end)
        end)

        describe("Yield Tracking", function()
            it("should track and satisfy yields", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local yield_info = {
                    yield_id = "yield-123",
                    reply_to = "test-topic",
                    pending_children = {
                        ["child-1"] = consts.STATUS.PENDING
                    },
                    results = {}
                }

                ws:track_yield("parent-1", yield_info)
                expect(ws.active_yields["parent-1"]).not_to_be_nil()
                expect(ws:is_node_active("parent-1")).to_be_true()

                ws:satisfy_yield("parent-1", { result = "test" })
                expect(ws.active_yields["parent-1"]).to_be_nil()
                expect(#ws.queued_commands).to_be_greater_than(0)
            end)

            it("should handle yield child completion", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                -- Set up parent-child relationship
                ws.nodes["parent-1"] = { status = consts.STATUS.RUNNING, type = "parent" }
                ws.nodes["child-1"] = {
                    status = consts.STATUS.RUNNING,
                    type = "child",
                    parent_node_id = "parent-1"
                }

                local yield_info = {
                    yield_id = "yield-123",
                    pending_children = {
                        ["child-1"] = consts.STATUS.PENDING
                    },
                    results = {}
                }
                ws:track_yield("parent-1", yield_info)
                ws:track_process("child-1", "child-pid")

                local exit_info = ws:handle_process_exit("child-pid", true, "child result")

                expect(exit_info.yield_complete).not_to_be_nil()
                expect(exit_info.yield_complete.parent_id).to_equal("parent-1")
            end)
        end)

        describe("Input Tracking", function()
            it("should manage input requirements and availability", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws:set_input_requirements("node-1", {
                    required = { "config", "data" },
                    optional = { "metadata" }
                })

                expect(ws.input_tracker.requirements["node-1"]).not_to_be_nil()
                expect(type(ws.input_tracker.requirements["node-1"].required)).to_equal("table")
                expect(#ws.input_tracker.requirements["node-1"].required).to_equal(2)
                expect(type(ws.input_tracker.available["node-1"])).to_equal("table")
            end)

            it("should update input availability from data operations", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws:set_input_requirements("node-1", {
                    required = { "config" },
                    optional = {}
                })

                -- Simulate creating node input
                local results = {
                    results = {
                        {
                            input = {
                                type = consts.COMMAND_TYPES.CREATE_DATA,
                                payload = {
                                    data_type = consts.DATA_TYPE.NODE_INPUT,
                                    node_id = "node-1",
                                    key = "config"
                                }
                            }
                        }
                    }
                }

                ws:_update_state_from_results(results)

                expect(ws.input_tracker.available["node-1"]["config"]).to_be_true()
            end)
        end)

        describe("Command Queuing and Persistence", function()
            it("should queue and persist commands", function()
                -- Commit test transaction to avoid conflicts
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local unique_node_id = "new-node-" .. uuid.v7()
                ws:queue_commands({
                    type = consts.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = unique_node_id,
                        node_type = "test_node"
                    }
                })

                expect(#ws.queued_commands).to_equal(1)

                local result, err = ws:persist()
                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#ws.queued_commands).to_equal(0)
            end)

            it("should handle empty command queue", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, err = ws:persist()
                expect(err).to_be_nil()
                expect(result.changes_made).to_be_false()
            end)

            it("should queue arrays of commands", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws:queue_commands({
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = { node_id = "node-1", node_type = "test" }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = { node_id = "node-2", node_type = "test" }
                    }
                })

                expect(#ws.queued_commands).to_equal(2)
            end)
        end)

        describe("State Updates from Results", function()
            it("should update node state from CREATE_NODE results", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local results = {
                    results = {
                        {
                            node_id = "new-node",
                            input = {
                                type = consts.COMMAND_TYPES.CREATE_NODE,
                                payload = {
                                    node_type = "test_node",
                                    status = consts.STATUS.PENDING
                                }
                            }
                        }
                    }
                }

                ws:_update_state_from_results(results)

                expect(ws.nodes["new-node"]).not_to_be_nil()
                expect(ws.nodes["new-node"].type).to_equal("test_node")
                expect(ws.nodes["new-node"].status).to_equal(consts.STATUS.PENDING)
            end)

            it("should update node state from UPDATE_NODE results", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws.nodes["existing-node"] = {
                    status = consts.STATUS.PENDING,
                    type = "test_node"
                }

                local results = {
                    results = {
                        {
                            input = {
                                type = consts.COMMAND_TYPES.UPDATE_NODE,
                                payload = {
                                    node_id = "existing-node",
                                    status = consts.STATUS.RUNNING
                                }
                            }
                        }
                    }
                }

                ws:_update_state_from_results(results)

                expect(ws.nodes["existing-node"].status).to_equal(consts.STATUS.RUNNING)
            end)

            it("should detect workflow output creation", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local results = {
                    results = {
                        {
                            input = {
                                type = consts.COMMAND_TYPES.CREATE_DATA,
                                payload = {
                                    data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                    content = "test output"
                                }
                            }
                        }
                    }
                }

                ws:_update_state_from_results(results)

                expect(ws.has_workflow_output).to_be_true()
            end)
        end)

        describe("Commit Processing", function()
            it("should process commit IDs and update state", function()
                -- Commit test transaction to avoid conflicts
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                -- This would normally come from commit.submit, but we'll simulate
                -- For now, test that empty commit list works
                local result, err = ws:process_commits({})
                expect(err).to_be_nil()
                expect(result.changes_made).to_be_false()
            end)
        end)

        describe("Activity Tracking", function()
            it("should correctly identify active nodes", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                -- Node is active if running
                ws:track_process("node-1", "pid-1")
                expect(ws:is_node_active("node-1")).to_be_true()

                -- Node is active if yielding
                ws:track_yield("node-2", { yield_id = "y1" })
                expect(ws:is_node_active("node-2")).to_be_true()

                -- Node is active if child of active yield
                ws:track_yield("parent", {
                    yield_id = "y2",
                    pending_children = { ["child"] = consts.STATUS.PENDING }
                })
                expect(ws:is_node_active("child")).to_be_true()

                -- Node is not active otherwise
                expect(ws:is_node_active("inactive-node")).to_be_false()
            end)
        end)

        describe("Edge Cases", function()
            it("should handle loading non-existent dataflow", function()
                -- Close test transaction to avoid conflicts
                test_ctx.tx:rollback()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                -- Use a clearly fake ID that won't exist
                local fake_id = "fake-dataflow-id-" .. uuid.v7()
                local ws, create_err = workflow_state.new(fake_id)
                expect(create_err).to_be_nil()
                expect(ws).not_to_be_nil()

                local result, load_err = ws:load_state()

                -- Should fail when trying to load non-existent dataflow
                expect(result).to_be_nil()
                expect(load_err).not_to_be_nil()
                expect(load_err).to_contain("not found")
            end)

            it("should handle multiple load_state calls", function()
                -- Commit test data first
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result1, load_err1 = ws:load_state()
                expect(load_err1).to_be_nil()
                expect(ws.loaded).to_be_true()

                -- Second call should be no-op
                local result2, load_err2 = ws:load_state()
                expect(load_err2).to_be_nil()
                expect(ws.loaded).to_be_true()
            end)

            it("should handle yield completion with no children", function()
                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws:track_yield("parent", {
                    yield_id = "empty-yield",
                    pending_children = {}
                })

                ws:satisfy_yield("parent", {})
                expect(ws.active_yields["parent"]).to_be_nil()
            end)
        end)

        describe("Yield Recovery", function()
            it("should reconstruct simple yield with pending children", function()
                -- Create parent node that was RUNNING (will be reset to PENDING)
                local parent_id = uuid.v7()
                local child1_id = uuid.v7()
                local child2_id = uuid.v7()
                local yield_id = uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent_id,
                        type = "parent_node",
                        status = consts.STATUS.RUNNING -- Will be reset to PENDING
                    },
                    {
                        node_id = child1_id,
                        type = "child_node",
                        parent_node_id = parent_id,
                        status = consts.STATUS.PENDING
                    },
                    {
                        node_id = child2_id,
                        type = "child_node",
                        parent_node_id = parent_id,
                        status = consts.STATUS.COMPLETED_SUCCESS
                    }
                })

                -- Create NODE_YIELD record showing the parent was yielding
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = yield_id,
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "%s",
                                    "reply_to": "test.yield_reply.%s",
                                    "yield_context": {
                                        "run_nodes": ["%s", "%s"]
                                    },
                                    "timestamp": "2023-01-01T12:00:00Z"
                                }]], parent_id, yield_id, parent_id, child1_id, child2_id),
                        content_type = "application/json"
                    }
                })

                -- Commit test data
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                -- Verify parent was reset to PENDING
                expect(ws.nodes[parent_id].status).to_equal(consts.STATUS.PENDING)

                -- Verify yield was reconstructed
                expect(ws.active_yields[parent_id]).not_to_be_nil()
                local yield_info = ws.active_yields[parent_id]
                expect(yield_info.yield_id).to_equal(yield_id)
                expect(yield_info.reply_to).to_equal("test.yield_reply." .. parent_id)

                -- Verify pending children state
                expect(yield_info.pending_children[child1_id]).to_equal(consts.STATUS.PENDING)
                expect(yield_info.pending_children[child2_id]).to_equal(consts.STATUS.COMPLETED_SUCCESS)

                -- Verify node is considered active
                expect(ws:is_node_active(parent_id)).to_be_true()
            end)

            it("should reconstruct yield that's ready to be satisfied", function()
                -- Create parent and children where all children are complete
                local parent_id = uuid.v7()
                local child1_id = uuid.v7()
                local child2_id = uuid.v7()
                local yield_id = uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent_id,
                        type = "parent_node",
                        status = consts.STATUS.RUNNING
                    },
                    {
                        node_id = child1_id,
                        type = "child_node",
                        parent_node_id = parent_id,
                        status = consts.STATUS.COMPLETED_SUCCESS
                    },
                    {
                        node_id = child2_id,
                        type = "child_node",
                        parent_node_id = parent_id,
                        status = consts.STATUS.COMPLETED_SUCCESS
                    }
                })

                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = yield_id,
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "%s",
                                    "reply_to": "test.yield_reply.%s",
                                    "yield_context": {
                                        "run_nodes": ["%s", "%s"]
                                    }
                                }]], parent_id, yield_id, parent_id, child1_id, child2_id)
                    },
                    -- Create NODE_RESULT records for completed children
                    {
                        node_id = child1_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.success",
                        content = '{"result": "child1 success"}'
                    },
                    {
                        node_id = child2_id,
                        type = consts.DATA_TYPE.NODE_RESULT,
                        discriminator = "result.success",
                        content = '{"result": "child2 success"}'
                    }
                })

                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                -- Verify yield was reconstructed with all children complete
                expect(ws.active_yields[parent_id]).not_to_be_nil()
                local yield_info = ws.active_yields[parent_id]

                -- Both children should be marked as complete
                expect(yield_info.pending_children[child1_id]).to_equal(consts.STATUS.COMPLETED_SUCCESS)
                expect(yield_info.pending_children[child2_id]).to_equal(consts.STATUS.COMPLETED_SUCCESS)

                -- Results should be populated with data IDs
                expect(yield_info.results[child1_id]).not_to_be_nil()
                expect(yield_info.results[child2_id]).not_to_be_nil()
            end)

            it("should handle multiple yields to reconstruct", function()
                local parent1_id = uuid.v7()
                local parent2_id = uuid.v7()
                local child1_id = uuid.v7()
                local child2_id = uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent1_id,
                        type = "parent_node",
                        status = consts.STATUS.RUNNING
                    },
                    {
                        node_id = parent2_id,
                        type = "parent_node",
                        status = consts.STATUS.RUNNING
                    },
                    {
                        node_id = child1_id,
                        type = "child_node",
                        parent_node_id = parent1_id,
                        status = consts.STATUS.PENDING
                    },
                    {
                        node_id = child2_id,
                        type = "child_node",
                        parent_node_id = parent2_id,
                        status = consts.STATUS.PENDING
                    }
                })

                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent1_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "yield1",
                                    "yield_context": {"run_nodes": ["%s"]}
                                }]], parent1_id, child1_id)
                    },
                    {
                        node_id = parent2_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "yield2",
                                    "yield_context": {"run_nodes": ["%s"]}
                                }]], parent2_id, child2_id)
                    }
                })

                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                -- Both yields should be reconstructed
                expect(ws.active_yields[parent1_id]).not_to_be_nil()
                expect(ws.active_yields[parent2_id]).not_to_be_nil()
                expect(ws.active_yields[parent1_id].yield_id).to_equal("yield1")
                expect(ws.active_yields[parent2_id].yield_id).to_equal("yield2")
            end)

            it("should ignore yields for nodes that are no longer PENDING", function()
                -- Create a node that completed successfully - its yield should not be reconstructed
                local completed_parent_id = uuid.v7()
                local child_id = uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = completed_parent_id,
                        type = "parent_node",
                        status = consts.STATUS.COMPLETED_SUCCESS -- Already completed
                    },
                    {
                        node_id = child_id,
                        type = "child_node",
                        parent_node_id = completed_parent_id,
                        status = consts.STATUS.PENDING
                    }
                })

                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = completed_parent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "stale-yield",
                                    "yield_context": {"run_nodes": ["%s"]}
                                }]], completed_parent_id, child_id)
                    }
                })

                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                -- No yield should be reconstructed for completed node
                expect(ws.active_yields[completed_parent_id]).to_be_nil()
                expect(ws:is_node_active(completed_parent_id)).to_be_false()
            end)

            it("should handle yields with missing child nodes", function()
                -- Yield references a child that no longer exists
                local parent_id = uuid.v7()
                local missing_child_id = uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent_id,
                        type = "parent_node",
                        status = consts.STATUS.RUNNING
                    }
                    -- Note: missing_child_id is not created
                })

                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "orphan-yield",
                                    "yield_context": {"run_nodes": ["%s"]}
                                }]], parent_id, missing_child_id)
                    }
                })

                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                -- Yield should be reconstructed but missing child treated as completed
                expect(ws.active_yields[parent_id]).not_to_be_nil()
                local yield_info = ws.active_yields[parent_id]
                -- Missing child should be marked as completed (or not included)
                expect(yield_info.pending_children[missing_child_id]).to_be_nil()
            end)

            it("should handle empty yields (no run_nodes)", function()
                local parent_id = uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent_id,
                        type = "parent_node",
                        status = consts.STATUS.RUNNING
                    }
                })

                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = parent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "empty-yield",
                                    "yield_context": {"run_nodes": []}
                                }]], parent_id)
                    }
                })

                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                -- Empty yield should be immediately satisfiable
                expect(ws.active_yields[parent_id]).not_to_be_nil()
                local yield_info = ws.active_yields[parent_id]
                expect(next(yield_info.pending_children)).to_be_nil() -- Empty table
            end)

            it("should reconstruct child path correctly", function()
                -- Test nested yields: grandparent -> parent -> child
                local grandparent_id = uuid.v7()
                local parent_id = uuid.v7()
                local child_id = uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = grandparent_id,
                        type = "grandparent_node",
                        status = consts.STATUS.RUNNING
                    },
                    {
                        node_id = parent_id,
                        type = "parent_node",
                        parent_node_id = grandparent_id,
                        status = consts.STATUS.RUNNING
                    },
                    {
                        node_id = child_id,
                        type = "child_node",
                        parent_node_id = parent_id,
                        status = consts.STATUS.PENDING
                    }
                })

                -- Create yields at both levels
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = grandparent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "gp-yield",
                                    "yield_context": {"run_nodes": ["%s"]},
                                    "child_path": []
                                }]], grandparent_id, parent_id)
                    },
                    {
                        node_id = parent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                    "node_id": "%s",
                                    "yield_id": "p-yield",
                                    "yield_context": {"run_nodes": ["%s"]},
                                    "child_path": ["%s"]
                                }]], parent_id, child_id, grandparent_id)
                    }
                })

                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                -- Both yields should be reconstructed with correct paths
                expect(ws.active_yields[grandparent_id]).not_to_be_nil()
                expect(ws.active_yields[parent_id]).not_to_be_nil()

                local parent_yield = ws.active_yields[parent_id]
                expect(type(parent_yield.child_path)).to_equal("table")
                expect(parent_yield.child_path[1]).to_equal(grandparent_id)
            end)

            it("should reconstruct chain of active yields (grandparent->parent->child)", function()
                -- Test scenario: 3-level chain where ALL levels were yielding when crashed
                local grandparent_id = uuid.v7()
                local parent_id = uuid.v7()
                local child_id = uuid.v7()
                local grandchild_id = uuid.v7()

                create_test_nodes(test_ctx.tx, test_ctx.dataflow_id, {
                    {
                        node_id = grandparent_id,
                        type = "chain_grandparent",
                        status = consts.STATUS.RUNNING -- Was yielding
                    },
                    {
                        node_id = parent_id,
                        type = "chain_parent",
                        parent_node_id = grandparent_id,
                        status = consts.STATUS.RUNNING -- Was also yielding
                    },
                    {
                        node_id = child_id,
                        type = "chain_child",
                        parent_node_id = parent_id,
                        status = consts.STATUS.RUNNING -- Was also yielding
                    },
                    {
                        node_id = grandchild_id,
                        type = "chain_grandchild",
                        parent_node_id = child_id,
                        status = consts.STATUS.PENDING -- Actual work node
                    }
                })

                -- Create NODE_YIELD records for each level
                create_test_data(test_ctx.tx, test_ctx.dataflow_id, {
                    -- Grandparent yield: spawned parent
                    {
                        node_id = grandparent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                        "node_id": "%s",
                                        "yield_id": "gp-chain-yield",
                                        "reply_to": "test.yield_reply.%s",
                                        "yield_context": {"run_nodes": ["%s"]},
                                        "child_path": []
                                    }]], grandparent_id, grandparent_id, parent_id)
                    },
                    -- Parent yield: spawned child
                    {
                        node_id = parent_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                        "node_id": "%s",
                                        "yield_id": "p-chain-yield",
                                        "reply_to": "test.yield_reply.%s",
                                        "yield_context": {"run_nodes": ["%s"]},
                                        "child_path": ["%s"]
                                    }]], parent_id, parent_id, child_id, grandparent_id)
                    },
                    -- Child yield: spawned grandchild
                    {
                        node_id = child_id,
                        type = consts.DATA_TYPE.NODE_YIELD,
                        key = uuid.v7(),
                        content = string.format([[{
                                        "node_id": "%s",
                                        "yield_id": "c-chain-yield",
                                        "reply_to": "test.yield_reply.%s",
                                        "yield_context": {"run_nodes": ["%s"]},
                                        "child_path": ["%s", "%s"]
                                    }]], child_id, child_id, grandchild_id, grandparent_id, parent_id)
                    }
                })

                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                local result, load_err = ws:load_state()
                expect(load_err).to_be_nil()

                -- All three yielding nodes should be reset to PENDING
                expect(ws.nodes[grandparent_id].status).to_equal(consts.STATUS.PENDING)
                expect(ws.nodes[parent_id].status).to_equal(consts.STATUS.PENDING)
                expect(ws.nodes[child_id].status).to_equal(consts.STATUS.PENDING)
                expect(ws.nodes[grandchild_id].status).to_equal(consts.STATUS.PENDING)

                -- All three yields should be reconstructed
                expect(ws.active_yields[grandparent_id]).not_to_be_nil()
                expect(ws.active_yields[parent_id]).not_to_be_nil()
                expect(ws.active_yields[child_id]).not_to_be_nil()

                -- Verify yield structure
                local gp_yield = ws.active_yields[grandparent_id]
                local p_yield = ws.active_yields[parent_id]
                local c_yield = ws.active_yields[child_id]

                expect(gp_yield.yield_id).to_equal("gp-chain-yield")
                expect(gp_yield.pending_children[parent_id]).to_equal(consts.STATUS.PENDING)

                expect(p_yield.yield_id).to_equal("p-chain-yield")
                expect(p_yield.pending_children[child_id]).to_equal(consts.STATUS.PENDING)
                expect(#p_yield.child_path).to_equal(1)
                expect(p_yield.child_path[1]).to_equal(grandparent_id)

                expect(c_yield.yield_id).to_equal("c-chain-yield")
                expect(c_yield.pending_children[grandchild_id]).to_equal(consts.STATUS.PENDING)
                expect(#c_yield.child_path).to_equal(2)
                expect(c_yield.child_path[1]).to_equal(grandparent_id)
                expect(c_yield.child_path[2]).to_equal(parent_id)

                -- All nodes should be considered active
                expect(ws:is_node_active(grandparent_id)).to_be_true()
                expect(ws:is_node_active(parent_id)).to_be_true()
                expect(ws:is_node_active(child_id)).to_be_true()
                expect(ws:is_node_active(grandchild_id)).to_be_true()

                -- Verify that scheduler would get the complete chain state
                local snapshot = ws:get_scheduler_snapshot()
                expect(next(snapshot.active_yields)).not_to_be_nil()
                expect(snapshot.active_yields[grandparent_id]).not_to_be_nil()
                expect(snapshot.active_yields[parent_id]).not_to_be_nil()
                expect(snapshot.active_yields[child_id]).not_to_be_nil()
            end)
        end)

        describe("Node Input Configuration", function()
            local config_test_nodes = {}  -- Track nodes created in this section

            after_all(function()
                -- Clean up any nodes created in this test section
                if #config_test_nodes > 0 then
                    local cleanup_db, err_db = sql.get("app:db")
                    if not err_db then
                        for _, node_id in ipairs(config_test_nodes) do
                            cleanup_db:execute("DELETE FROM nodes WHERE node_id = ?", { node_id })
                            cleanup_db:execute("DELETE FROM data WHERE node_id = ?", { node_id })
                        end
                        cleanup_db:release()
                    end
                    config_test_nodes = {}
                end
            end)

            it("should set input requirements when node config specifies inputs", function()
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local node_id = uuid.v7()
                table.insert(config_test_nodes, node_id)

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws:queue_commands({
                    type = consts.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = node_id,
                        node_type = "test_node_type",
                        status = consts.STATUS.PENDING,
                        config = {
                            inputs = {
                                required = { "data", "config" },
                                optional = { "metadata" }
                            }
                        }
                    }
                })

                local result, err = ws:persist()
                expect(err).to_be_nil()

                expect(ws.input_tracker.requirements[node_id]).not_to_be_nil()
                expect(ws.input_tracker.requirements[node_id].required).to_contain("data")
                expect(ws.input_tracker.requirements[node_id].required).to_contain("config")
                expect(ws.input_tracker.requirements[node_id].optional).to_contain("metadata")
            end)

            it("should load input requirements from node config during load_state", function()
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local node_id = uuid.v7()
                table.insert(config_test_nodes, node_id)

                local ws1, create_err1 = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err1).to_be_nil()

                ws1:queue_commands({
                    type = consts.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = node_id,
                        node_type = "test_node",
                        status = consts.STATUS.PENDING,
                        config = {
                            inputs = {
                                required = { "input_data" },
                                optional = { "extra_params" }
                            }
                        }
                    }
                })

                local persist_result, persist_err = ws1:persist()
                expect(persist_err).to_be_nil()

                local ws2, create_err2 = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err2).to_be_nil()

                local load_result, load_err = ws2:load_state()
                expect(load_err).to_be_nil()

                expect(ws2.input_tracker.requirements[node_id]).not_to_be_nil()
                expect(ws2.input_tracker.requirements[node_id].required).to_contain("input_data")
                expect(ws2.input_tracker.requirements[node_id].optional).to_contain("extra_params")
            end)

            it("should handle nodes without input configuration gracefully", function()
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local node_id = uuid.v7()
                table.insert(config_test_nodes, node_id)

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws:queue_commands({
                    type = consts.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = node_id,
                        node_type = "simple_node",
                        status = consts.STATUS.PENDING
                    }
                })

                local persist_result, persist_err = ws:persist()
                expect(persist_err).to_be_nil()

                expect(ws.nodes[node_id]).not_to_be_nil()
                expect(ws.input_tracker.requirements[node_id]).to_be_nil()
            end)

            it("should provide scheduler snapshot with loaded input requirements", function()
                test_ctx.tx:commit()
                test_ctx.db:release()
                test_ctx.tx = nil
                test_ctx.db = nil

                local node_id = uuid.v7()
                table.insert(config_test_nodes, node_id)

                local ws, create_err = workflow_state.new(test_ctx.dataflow_id)
                expect(create_err).to_be_nil()

                ws:queue_commands({
                    type = consts.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = node_id,
                        node_type = "test_node",
                        status = consts.STATUS.PENDING,
                        config = {
                            inputs = {
                                required = { "essential_data" },
                                optional = { "nice_to_have" }
                            }
                        }
                    }
                })

                local persist_result, persist_err = ws:persist()
                expect(persist_err).to_be_nil()

                local snapshot = ws:get_scheduler_snapshot()

                expect(snapshot.input_tracker.requirements[node_id]).not_to_be_nil()
                expect(snapshot.input_tracker.requirements[node_id].required).to_contain("essential_data")
                expect(snapshot.input_tracker.requirements[node_id].optional).to_contain("nice_to_have")
            end)
        end)

    end)
end

return test.run_cases(define_tests)