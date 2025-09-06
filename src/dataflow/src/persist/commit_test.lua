local test = require("test")
local uuid = require("uuid")
local json = require("json")
local time = require("time")
local sql = require("sql")
local security = require("security")

local commit = require("commit")
local commit_repo = require("commit_repo")
local ops = require("ops")

local function define_tests()
    describe("Commit Module", function()
        local test_ctx = {
            db = nil,
            tx = nil,
            resources = nil,
            mocks = {}
        }

        -- Mock storage for tracking calls
        local mock_calls = {}

        -- Helper function to setup mocks
        local function setup_mocks()
            mock_calls = {
                process_messages = {},
                user_id_calls = 0,
                timestamp_calls = 0
            }

            -- Mock process message sending
            test_ctx.mocks.original_send_process_message = commit._send_process_message
            commit._send_process_message = function(target_process, topic, payload)
                table.insert(mock_calls.process_messages, {
                    target_process = target_process,
                    topic = topic,
                    payload = payload
                })
            end

            -- Mock user ID retrieval
            test_ctx.mocks.original_get_current_user_id = commit._get_current_user_id
            commit._get_current_user_id = function()
                mock_calls.user_id_calls = mock_calls.user_id_calls + 1
                return "test-user-123"
            end

            -- Mock timestamp retrieval
            test_ctx.mocks.original_get_current_timestamp = commit._get_current_timestamp
            commit._get_current_timestamp = function()
                mock_calls.timestamp_calls = mock_calls.timestamp_calls + 1
                return "2023-01-01T12:00:00.123456789Z"
            end
        end

        -- Helper function to restore mocks
        local function restore_mocks()
            if test_ctx.mocks.original_send_process_message then
                commit._send_process_message = test_ctx.mocks.original_send_process_message
            end
            if test_ctx.mocks.original_get_current_user_id then
                commit._get_current_user_id = test_ctx.mocks.original_get_current_user_id
            end
            if test_ctx.mocks.original_get_current_timestamp then
                commit._get_current_timestamp = test_ctx.mocks.original_get_current_timestamp
            end
            test_ctx.mocks = {}
        end

        before_each(function()
            setup_mocks()

            local db, err_db = sql.get("app:db")
            if err_db then error("Failed to connect to database: " .. err_db) end
            test_ctx.db = db

            local tx, err_tx = db:begin()
            if err_tx then
                db:release()
                test_ctx.db = nil
                error("Failed to begin transaction: " .. err_tx)
            end
            test_ctx.tx = tx
        end)

        after_each(function()
            restore_mocks()

            if test_ctx.tx then
                test_ctx.tx:rollback()
                test_ctx.tx = nil
            end

            if test_ctx.db then
                test_ctx.db:release()
                test_ctx.db = nil
            end

            test_ctx.resources = nil
        end)

        local function get_test_transaction()
            return test_ctx.tx
        end

        local function setup_test_resources()
            local test_actor_id = "test-user-" .. uuid.v7()
            local tx = get_test_transaction()

            local dataflow_id = uuid.v7()
            local now_ts = time.now():format(time.RFC3339NANO)

            local success, err_insert = tx:execute([[
                INSERT INTO dataflows (
                    dataflow_id, actor_id, type, status, metadata, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ]], {
                dataflow_id,
                test_actor_id,
                "test_dataflow",
                "active",
                "{}",
                now_ts,
                now_ts
            })

            if err_insert then
                error("Failed to create test dataflow: " .. err_insert)
            end

            test_ctx.resources = {
                actor_id = test_actor_id,
                dataflow_id = dataflow_id
            }

            return test_ctx.resources
        end

        -- Helper function to create isolated dataflow for tests that need their own transactions
        local function create_isolated_dataflow()
            local dataflow_id = uuid.v7()
            local actor_id = "test-actor-" .. uuid.v7()
            local now_ts = time.now():format(time.RFC3339NANO)

            local db, err_db = sql.get("app:db")
            if err_db then
                error("Failed to connect to database: " .. err_db)
            end

            local tx, err_tx = db:begin()
            if err_tx then
                db:release()
                error("Failed to begin transaction: " .. err_tx)
            end

            local _, err_create = tx:execute([[
                INSERT INTO dataflows (
                    dataflow_id, actor_id, type, status, metadata, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ]], {
                dataflow_id,
                actor_id,
                "test_dataflow",
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

            local _, err_commit = tx:commit()
            if err_commit then
                tx:rollback()
                db:release()
                error("Failed to commit dataflow creation: " .. err_commit)
            end

            db:release()
            return dataflow_id
        end

        describe("publish_updates", function()
            it("should do nothing when result has no changes", function()
                local result = {
                    changes_made = false,
                    results = {}
                }

                commit.publish_updates("test-dataflow-id", "test-op-id", result)

                expect(#mock_calls.process_messages).to_equal(0)
                expect(mock_calls.user_id_calls).to_equal(0)
                expect(mock_calls.timestamp_calls).to_equal(0)
            end)

            it("should do nothing when result is nil", function()
                commit.publish_updates("test-dataflow-id", "test-op-id", nil)

                expect(#mock_calls.process_messages).to_equal(0)
            end)

            it("should send workflow updates for CREATE_WORKFLOW command", function()
                local dataflow_id = "test-dataflow-id"
                local op_id = "test-op-id"
                local result = {
                    changes_made = true,
                    results = {
                        {
                            changes_made = true,
                            input = {
                                type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                                payload = {
                                    type = "test_workflow",
                                    status = "active",
                                    metadata = { test = "data" }
                                }
                            }
                        }
                    }
                }

                commit.publish_updates(dataflow_id, op_id, result)

                expect(mock_calls.user_id_calls).to_equal(1)
                expect(mock_calls.timestamp_calls).to_equal(1)
                -- Current implementation only sends basic workflow event when no node events
                expect(#mock_calls.process_messages).to_equal(1)

                -- Check the workflow event message
                local msg = mock_calls.process_messages[1]
                expect(msg.target_process).to_equal("user.test-user-123")
                expect(msg.topic).to_equal("dataflow:" .. dataflow_id)
                expect(msg.payload.dataflow_id).to_equal(dataflow_id)
                expect(msg.payload.updated_at).not_to_be_nil()
            end)

            it("should send only node update for CREATE_NODE command", function()
                local dataflow_id = "test-dataflow-id"
                local op_id = "test-op-id"
                local node_id = "test-node-id"
                local result = {
                    changes_made = true,
                    results = {
                        {
                            changes_made = true,
                            node_id = node_id,
                            input = {
                                type = ops.COMMAND_TYPES.CREATE_NODE,
                                payload = {
                                    node_type = "test_node",
                                    status = "pending",
                                    metadata = { node = "data" }
                                }
                            }
                        }
                    }
                }

                commit.publish_updates(dataflow_id, op_id, result)

                -- Should only send 1 message (node update to dataflow topic)
                expect(#mock_calls.process_messages).to_equal(1)

                local msg = mock_calls.process_messages[1]
                expect(msg.target_process).to_equal("user.test-user-123")
                expect(msg.topic).to_equal("dataflow:" .. dataflow_id)
                expect(msg.payload.node_id).to_equal(node_id)
                expect(msg.payload.op_type).to_equal(ops.COMMAND_TYPES.CREATE_NODE)
                expect(msg.payload.deleted).to_equal(false)
            end)

            it("should mark deleted=true for DELETE_NODE command", function()
                local dataflow_id = "test-dataflow-id"
                local op_id = "test-op-id"
                local result = {
                    changes_made = true,
                    results = {
                        {
                            changes_made = true,
                            node_id = "test-node-id",
                            input = {
                                type = ops.COMMAND_TYPES.DELETE_NODE,
                                payload = {}
                            }
                        }
                    }
                }

                commit.publish_updates(dataflow_id, op_id, result)

                expect(#mock_calls.process_messages).to_equal(1)
                expect(mock_calls.process_messages[1].payload.deleted).to_equal(true)
            end)

            it("should send workflow event when no node events present", function()
                local dataflow_id = "test-dataflow-id"
                local op_id = "test-op-id"
                local result = {
                    changes_made = true,
                    results = {
                        {
                            changes_made = true,
                            input = {
                                type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                                payload = {
                                    status = "completed",
                                    metadata = { final = "state" }
                                }
                            }
                        }
                    }
                }

                commit.publish_updates(dataflow_id, op_id, result)

                expect(mock_calls.user_id_calls).to_equal(1)
                expect(mock_calls.timestamp_calls).to_equal(1)
                -- Should send basic workflow event when no node events
                expect(#mock_calls.process_messages).to_equal(1)

                local msg = mock_calls.process_messages[1]
                expect(msg.target_process).to_equal("user.test-user-123")
                expect(msg.topic).to_equal("dataflow:" .. dataflow_id)
                expect(msg.payload.dataflow_id).to_equal(dataflow_id)
                expect(msg.payload.updated_at).not_to_be_nil()
            end)

            it("should handle mixed operation types", function()
                local dataflow_id = "test-dataflow-id"
                local op_id = "test-op-id"
                local result = {
                    changes_made = true,
                    results = {
                        {
                            changes_made = true,
                            input = {
                                type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                                payload = { type = "test_workflow" }
                            }
                        },
                        {
                            changes_made = true,
                            node_id = "test-node-id",
                            input = {
                                type = ops.COMMAND_TYPES.CREATE_NODE,
                                payload = { node_type = "test_node" }
                            }
                        }
                    }
                }

                commit.publish_updates(dataflow_id, op_id, result)

                -- Current implementation: when there are node events, workflow events are suppressed
                -- Should only send 1 message for the node operation
                expect(#mock_calls.process_messages).to_equal(1)

                -- Verify it's the node message
                local msg = mock_calls.process_messages[1]
                expect(msg.topic).to_equal("dataflow:" .. dataflow_id)
                expect(msg.payload.node_id).to_equal("test-node-id")
                expect(msg.payload.op_type).to_equal(ops.COMMAND_TYPES.CREATE_NODE)
            end)
        end)

        describe("tx_execute", function()
            it("should execute commands within provided transaction", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local commands = {
                    {
                        type = ops.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = uuid.v7(),
                            node_type = "test_node"
                        }
                    }
                }

                local result, err = commit.tx_execute(tx, resources.dataflow_id, nil, commands, { publish = false })

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).not_to_be_nil()

                -- Should not publish when publish=false
                expect(#mock_calls.process_messages).to_equal(0)
            end)

            it("should fail with missing transaction", function()
                local commands = {
                    {
                        type = ops.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = uuid.v7(),
                            node_type = "test_node"
                        }
                    }
                }

                local result, err = commit.tx_execute(nil, uuid.v7(), nil, commands)

                expect(result).to_be_nil()
                expect(err).to_contain("Transaction is required")
            end)

            it("should expand APPLY_COMMIT commands", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                -- Manually insert a commit record to avoid nested transaction
                local commit_id = uuid.v7()
                local commit_payload = {
                    op_id = uuid.v7(),
                    commands = {
                        {
                            type = ops.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = uuid.v7(),
                                node_type = "commit_test_node"
                            }
                        }
                    }
                }

                local payload_json = json.encode(commit_payload)
                local now_ts = time.now():format(time.RFC3339NANO)

                -- Insert commit directly using existing transaction
                local _, insert_err = tx:execute([[
                    INSERT INTO dataflow_commits (
                        commit_id, dataflow_id, op_id, execution_id, payload, metadata, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                ]], {
                    commit_id,
                    resources.dataflow_id,
                    nil, -- op_id
                    nil, -- execution_id
                    payload_json,
                    "{}",
                    now_ts
                })
                expect(insert_err).to_be_nil()

                -- Now test applying the commit
                local commands = {
                    {
                        type = "APPLY_COMMIT",
                        payload = {
                            commit_id = commit_id
                        }
                    }
                }

                local result, err = commit.tx_execute(tx, resources.dataflow_id, nil, commands, { publish = false })

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(result.commit_ids).not_to_be_nil()
                expect(#result.commit_ids).to_equal(1)
                expect(result.commit_ids[1]).to_equal(commit_id)

                -- Should have executed both the node creation and workflow update
                expect(#result.results).to_equal(2)
            end)
        end)

        describe("get_pending_commits - No Transaction Conflicts", function()
            it("should return empty array when no commits exist", function()
                -- Close the test transaction to avoid conflicts
                if test_ctx.tx then
                    test_ctx.tx:rollback()
                    test_ctx.tx = nil
                end
                if test_ctx.db then
                    test_ctx.db:release()
                    test_ctx.db = nil
                end

                local dataflow_id = create_isolated_dataflow()

                local commits, err = commit.get_pending_commits(dataflow_id)

                expect(err).to_be_nil()
                expect(commits).not_to_be_nil()
                expect(#commits).to_equal(0)
            end)

            it("should return all commits when no last_commit_id using submit", function()
                -- Close the test transaction to avoid conflicts
                if test_ctx.tx then
                    test_ctx.tx:rollback()
                    test_ctx.tx = nil
                end
                if test_ctx.db then
                    test_ctx.db:release()
                    test_ctx.db = nil
                end

                local dataflow_id = create_isolated_dataflow()

                -- Create a commit using submit (which should use _create_commit_only internally)
                local commands = {
                    {
                        type = ops.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = uuid.v7(),
                            node_type = "pending_test_node"
                        }
                    }
                }

                local submit_result, submit_err = commit.submit(dataflow_id, nil, commands)
                expect(submit_err).to_be_nil()
                expect(submit_result.commit_id).not_to_be_nil()

                local commits, err = commit.get_pending_commits(dataflow_id)

                expect(err).to_be_nil()
                expect(commits).not_to_be_nil()
                expect(#commits).to_equal(1)
                expect(commits[1]).to_equal(submit_result.commit_id)
            end)

            it("should fail with missing dataflow_id", function()
                local commits, err = commit.get_pending_commits(nil)

                expect(commits).to_be_nil()
                expect(err).to_contain("Dataflow ID is required")
            end)
        end)

        describe("Integration Tests - No Transaction Conflicts", function()
            it("should handle full workflow from submit to execute", function()
                -- Close the test transaction to avoid conflicts
                if test_ctx.tx then
                    test_ctx.tx:rollback()
                    test_ctx.tx = nil
                end
                if test_ctx.db then
                    test_ctx.db:release()
                    test_ctx.db = nil
                end

                local dataflow_id = create_isolated_dataflow()

                -- Step 1: Submit a commit
                local commands = {
                    {
                        type = ops.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = uuid.v7(),
                            node_type = "integration_test_node"
                        }
                    }
                }

                local submit_result, submit_err = commit.submit(dataflow_id, nil, commands)
                expect(submit_err).to_be_nil()
                expect(submit_result.commit_id).not_to_be_nil()

                -- Step 2: Get pending commits
                local pending_commits, pending_err = commit.get_pending_commits(dataflow_id)
                expect(pending_err).to_be_nil()
                expect(#pending_commits).to_equal(1)
                expect(pending_commits[1]).to_equal(submit_result.commit_id)

                -- Step 3: Execute the commit
                local apply_commands = {
                    {
                        type = "APPLY_COMMIT",
                        payload = {
                            commit_id = submit_result.commit_id
                        }
                    }
                }

                local execute_result, execute_err = commit.execute(dataflow_id, nil, apply_commands, { publish = false })
                expect(execute_err).to_be_nil()
                expect(execute_result.changes_made).to_be_true()
                expect(execute_result.commit_ids[1]).to_equal(submit_result.commit_id)

                -- Step 4: Verify no more pending commits
                local final_pending, final_err = commit.get_pending_commits(dataflow_id)
                expect(final_err).to_be_nil()
                expect(#final_pending).to_equal(0)
            end)
        end)

        describe("Edge Cases and Error Handling", function()
                    it("should handle get_pending_commits with non-existent dataflow", function()
                        -- Close the test transaction to avoid conflicts
                        if test_ctx.tx then
                            test_ctx.tx:rollback()
                            test_ctx.tx = nil
                        end
                        if test_ctx.db then
                            test_ctx.db:release()
                            test_ctx.db = nil
                        end

                        local fake_dataflow_id = uuid.v7()
                        local commits, err = commit.get_pending_commits(fake_dataflow_id)

                        expect(err).to_be_nil()
                        expect(commits).not_to_be_nil()
                        expect(#commits).to_equal(0)
                    end)

                    it("should handle execute with invalid commit ID in APPLY_COMMIT", function()
                        -- Close the test transaction to avoid conflicts
                        if test_ctx.tx then
                            test_ctx.tx:rollback()
                            test_ctx.tx = nil
                        end
                        if test_ctx.db then
                            test_ctx.db:release()
                            test_ctx.db = nil
                        end

                        local dataflow_id = create_isolated_dataflow()

                        local apply_commands = {
                            {
                                type = "APPLY_COMMIT",
                                payload = {
                                    commit_id = uuid.v7() -- Non-existent commit
                                }
                            }
                        }

                        local result, err = commit.execute(dataflow_id, nil, apply_commands)

                        expect(result).to_be_nil()
                        expect(err).to_contain("Commit not found")
                    end)

                    it("should preserve commit order with rapid submissions", function()
                        -- Close the test transaction to avoid conflicts
                        if test_ctx.tx then
                            test_ctx.tx:rollback()
                            test_ctx.tx = nil
                        end
                        if test_ctx.db then
                            test_ctx.db:release()
                            test_ctx.db = nil
                        end

                        local dataflow_id = create_isolated_dataflow()

                        -- Submit commits rapidly
                        local commit_ids = {}
                        for i = 1, 5 do
                            local commands = {
                                {
                                    type = ops.COMMAND_TYPES.CREATE_NODE,
                                    payload = {
                                        node_id = uuid.v7(),
                                        node_type = "rapid_test_node_" .. i
                                    }
                                }
                            }

                            local result, err = commit.submit(dataflow_id, nil, commands)
                            expect(err).to_be_nil()
                            table.insert(commit_ids, result.commit_id)
                        end

                        -- Verify all commits are pending in order
                        local pending_commits, pending_err = commit.get_pending_commits(dataflow_id)
                        expect(pending_err).to_be_nil()
                        expect(#pending_commits).to_equal(5)

                        -- Verify commit IDs are in ascending order (UUID v7 time-based)
                        for i = 2, #pending_commits do
                            expect(pending_commits[i] > pending_commits[i-1]).to_be_true()
                        end

                        -- Verify they match our submitted order
                        for i = 1, #commit_ids do
                            expect(pending_commits[i]).to_equal(commit_ids[i])
                        end
                    end)

                    it("should handle submit with invalid parameters", function()
                        -- Close the test transaction to avoid conflicts
                        if test_ctx.tx then
                            test_ctx.tx:rollback()
                            test_ctx.tx = nil
                        end
                        if test_ctx.db then
                            test_ctx.db:release()
                            test_ctx.db = nil
                        end

                        -- Test with empty string dataflow_id
                        local result1, err1 = commit.submit("", nil, {})
                        expect(result1).to_be_nil()
                        expect(err1).to_contain("Dataflow ID is required")

                        -- Test with nil commands
                        local result2, err2 = commit.submit(uuid.v7(), nil, nil)
                        expect(result2).to_be_nil()
                        expect(err2).to_contain("Commands must be a table or array of commands")
                    end)
                end)


    end)
end

return test.run_cases(define_tests)