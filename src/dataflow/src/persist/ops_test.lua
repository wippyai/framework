local test = require("test")
local uuid = require("uuid")
local json = require("json")
local time = require("time")
local sql = require("sql")
local security = require("security")

local ops = require("ops")

local function define_tests()
    describe("Operations Module", function()
        local test_ctx = {
            db = nil,
            tx = nil,
            resources = nil
        }

        before_each(function()
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
            local now_ts = time.now():format(time.RFC3339)

            local success, err_insert = tx:execute([[
                INSERT INTO dataflows (
                    dataflow_id, actor_id,  type, status, metadata, created_at, updated_at
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

            local node_id = uuid.v7()

            success, err_insert = tx:execute([[
                INSERT INTO nodes (
                    node_id, dataflow_id, type, status, config, metadata, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                node_id,
                dataflow_id,
                "test_node",
                "pending",
                "{}",
                "{}",
                now_ts,
                now_ts
            })

            if err_insert then
                error("Failed to create test node: " .. err_insert)
            end

            test_ctx.resources = {
                actor_id = test_actor_id,
                dataflow_id = dataflow_id,
                node_id = node_id
            }

            return test_ctx.resources
        end

        describe("Basic Operation Execution", function()
            it("should execute a single command successfully", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local data_id = uuid.v7()
                local command = {
                    type = ops.COMMAND_TYPES.CREATE_DATA,
                    payload = {
                        data_id = data_id,
                        node_id = resources.node_id,
                        key = "test_key",
                        discriminator = "test",
                        data_type = "test_data",
                        content = { value = "test content" },
                        content_type = "application/json",
                        metadata = { source = "ops_test" }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.op_id).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].data_id).to_equal(data_id)

                local query = "SELECT * FROM data WHERE data_id = ?"
                local rows, err_query = tx:query(query, { data_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].data_id).to_equal(data_id)
            end)

            it("should execute multiple commands in a batch", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local data_id_1 = uuid.v7()
                local data_id_2 = uuid.v7()

                local commands = {
                    {
                        type = "CREATE_DATA",
                        payload = {
                            data_id = data_id_1,
                            node_id = resources.node_id,
                            key = "batch_key_1",
                            discriminator = "test",
                            data_type = "test_data",
                            content = { value = "batch content 1" },
                            content_type = "application/json"
                        }
                    },
                    {
                        type = "CREATE_DATA",
                        payload = {
                            data_id = data_id_2,
                            key = "batch_key_2",
                            discriminator = "test",
                            data_type = "test_data",
                            content = { value = "batch content 2" },
                            content_type = "application/json"
                        }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, commands)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.op_id).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(2)
                expect(result.results[1].data_id).to_equal(data_id_1)
                expect(result.results[2].data_id).to_equal(data_id_2)

                local query = "SELECT * FROM data WHERE data_id IN (?, ?) ORDER BY key ASC"
                local rows, err_query = tx:query(query, { data_id_1, data_id_2 })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(2)
                expect(rows[1].key).to_equal("batch_key_1")
                expect(rows[2].key).to_equal("batch_key_2")
                expect(rows[1].node_id).to_equal(resources.node_id)
                expect(rows[2].node_id).to_be_nil()
            end)

            it("should fail with missing dataflow ID", function()
                local tx = get_test_transaction()

                local command = {
                    type = ops.COMMAND_TYPES.CREATE_DATA,
                    payload = {
                        data_id = uuid.v7(),
                        key = "error_test",
                        discriminator = "test",
                        data_type = "test_data",
                        content = "test"
                    }
                }

                local result, err = ops.execute(tx, nil, nil, command)

                expect(result).to_be_nil()
                expect(err).to_contain("Workflow ID is required")
            end)

            it("should fail with unknown command type", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local command = {
                    type = "unknown_command",
                    payload = {
                        some_field = "value"
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(result).to_be_nil()
                expect(err).to_contain("Unknown command type")
            end)

            it("should fail if a command in a batch fails", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local data_id_1 = uuid.v7()
                local data_id_2 = uuid.v7()

                local commands = {
                    {
                        type = ops.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = data_id_1,
                            key = "batch_error_key_1",
                            discriminator = "test",
                            data_type = "test_data",
                            content = "batch content 1"
                        }
                    },
                    {
                        type = ops.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = data_id_2,
                            key = "batch_error_key_2",
                            discriminator = "test"
                            -- data_type is missing (required field)
                            -- content is missing (required field)
                        }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, commands)

                expect(result).to_be_nil()
                expect(err).to_contain("Data type is required")

                -- Verify first command was executed but will be rolled back
                local query = "SELECT * FROM data WHERE data_id = ?"
                local rows, err_query = tx:query(query, { data_id_1 })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1) -- Record exists in transaction but will rollback
            end)
        end)

        describe("Workflow Operations", function()
            it("should create a dataflow using CREATE_WORKFLOW command with minimal fields", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()
                local command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "minimal_dataflow_type"
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.op_id).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].dataflow_id).to_equal(dataflow_id)

                local query = "SELECT * FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].dataflow_id).to_equal(dataflow_id)
                expect(rows[1].actor_id).to_equal(actor_id)
                expect(rows[1].type).to_equal("minimal_dataflow_type")
                expect(rows[1].status).to_equal("pending")
                expect(rows[1].parent_dataflow_id).to_be_nil()

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(next(metadata)).to_be_nil()

                expect(rows[1].created_at).not_to_be_nil()
                expect(rows[1].updated_at).not_to_be_nil()
                expect(rows[1].created_at).to_equal(rows[1].updated_at)
            end)

            it("should create a dataflow using CREATE_WORKFLOW command with all optional fields", function()
                local tx = get_test_transaction()

                local parent_dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local parent_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = parent_dataflow_id,
                        actor_id = actor_id,
                        type = "parent_dataflow_type"
                    }
                }

                local parent_result, parent_err = ops.execute(tx, parent_dataflow_id, nil, parent_command)
                expect(parent_err).to_be_nil()

                local dataflow_id = uuid.v7()
                local command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "full_dataflow_type",
                        status = "running",
                        parent_dataflow_id = parent_dataflow_id,
                        metadata = {
                            source = "ops_test",
                            purpose = "testing",
                            nested = { key = "value", num = 42 }
                        }
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.op_id).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].dataflow_id).to_equal(dataflow_id)

                local query = "SELECT * FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].dataflow_id).to_equal(dataflow_id)
                expect(rows[1].actor_id).to_equal(actor_id)
                expect(rows[1].type).to_equal("full_dataflow_type")
                expect(rows[1].status).to_equal("running")
                expect(rows[1].parent_dataflow_id).to_equal(parent_dataflow_id)

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(metadata.source).to_equal("ops_test")
                expect(metadata.purpose).to_equal("testing")
                expect(metadata.nested.key).to_equal("value")
                expect(metadata.nested.num).to_equal(42)
            end)

            it("should fail to create a dataflow without required fields", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local command1 = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        type = "test_dataflow"
                    }
                }

                local command2 = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id
                    }
                }

                local result1, err1 = ops.execute(tx, dataflow_id, nil, command1)
                expect(result1).to_be_nil()
                expect(err1).to_contain("User ID is required")

                local result2, err2 = ops.execute(tx, dataflow_id, nil, command2)
                expect(result2).to_be_nil()
                expect(err2).to_contain("Workflow type is required")
            end)

            it("should accept metadata as pre-encoded JSON string", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()
                local metadata_json_string = '{"json_key":"json_value","nested":{"num":123}}'

                local command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "json_string_meta",
                        metadata = metadata_json_string
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, command)
                expect(err).to_be_nil()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)

                local metadata = json.decode(rows[1].metadata)
                expect(metadata.json_key).to_equal("json_value")
                expect(metadata.nested.num).to_equal(123)
            end)

            it("should update a dataflow with UPDATE_WORKFLOW command", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "update_test_type",
                        metadata = { version = 1 }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()
                expect(create_result.changes_made).to_be_true()

                local check_query = "SELECT created_at FROM dataflows WHERE dataflow_id = ?"
                local check_rows, check_err = tx:query(check_query, { dataflow_id })
                expect(check_err).to_be_nil()
                local created_at = check_rows[1].created_at

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        status = "completed",
                        metadata = { version = 2, updated = true }
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].dataflow_id).to_equal(dataflow_id)

                local query = "SELECT * FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].status).to_equal("completed")

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(metadata.version).to_equal(2)
                expect(metadata.updated).to_be_true()

                expect(rows[1].updated_at >= created_at).to_be_true()
            end)

            it("should handle empty updates with UPDATE_WORKFLOW command", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "empty_update_test_type",
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()
                expect(create_result.changes_made).to_be_true()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {}
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_false()
                expect(#result.results).to_equal(1)
                expect(result.results[1].dataflow_id).to_equal(dataflow_id)
                expect(result.results[1].message).to_contain("No valid fields provided for update")
            end)

            it("should return error for non-existent dataflow ID on update", function()
                local tx = get_test_transaction()

                local fake_dataflow_id = uuid.v7()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        status = "failed"
                    }
                }

                local result, err = ops.execute(tx, fake_dataflow_id, nil, update_command)

                expect(result).to_be_nil()
                expect(err).to_contain("Workflow not found or no changes applied")
            end)

            it("should update dataflow status with UPDATE_WORKFLOW command", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "status_update_test_type"
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()
                expect(create_result.changes_made).to_be_true()

                local check_query = "SELECT status FROM dataflows WHERE dataflow_id = ?"
                local check_rows, check_err = tx:query(check_query, { dataflow_id })
                expect(check_err).to_be_nil()
                expect(check_rows[1].status).to_equal("pending")

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        status = "running"
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].dataflow_id).to_equal(dataflow_id)

                local query = "SELECT status FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].status).to_equal("running")
            end)

            it("should delete a dataflow with DELETE_WORKFLOW command", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "delete_test_type"
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()
                expect(create_result.changes_made).to_be_true()

                local check_query = "SELECT COUNT(*) AS wf_count FROM dataflows WHERE dataflow_id = ?"
                local check_rows, check_err = tx:query(check_query, { dataflow_id })
                expect(check_err).to_be_nil()
                expect(check_rows[1].wf_count).to_equal(1)

                local delete_command = {
                    type = ops.COMMAND_TYPES.DELETE_WORKFLOW,
                    payload = {}
                }

                local result, err = ops.execute(tx, dataflow_id, nil, delete_command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].dataflow_id).to_equal(dataflow_id)
                expect(result.results[1].deleted).to_be_true()

                local count_query = "SELECT COUNT(*) AS wf_count FROM dataflows WHERE dataflow_id = ?"
                local count_rows, count_err = tx:query(count_query, { dataflow_id })
                expect(count_err).to_be_nil()
                expect(count_rows[1].wf_count).to_equal(0)
            end)

            it("should return error when deleting non-existent dataflow", function()
                local tx = get_test_transaction()

                local fake_dataflow_id = uuid.v7()

                local delete_command = {
                    type = ops.COMMAND_TYPES.DELETE_WORKFLOW,
                    payload = {}
                }

                local result, err = ops.execute(tx, fake_dataflow_id, nil, delete_command)

                expect(result).to_be_nil()
                expect(err).to_contain("Workflow not found")
            end)

            it("should delete a specific dataflow when provided in command", function()
                local tx = get_test_transaction()

                local context_dataflow_id = uuid.v7()
                local delete_dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local context_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = context_dataflow_id,
                        actor_id = actor_id,
                        type = "context_dataflow_type"
                    }
                }

                local context_result, context_err = ops.execute(tx, context_dataflow_id, nil, context_command)
                expect(context_err).to_be_nil()

                local target_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = delete_dataflow_id,
                        actor_id = actor_id,
                        type = "target_delete_type"
                    }
                }

                local target_result, target_err = ops.execute(tx, delete_dataflow_id, nil, target_command)
                expect(target_err).to_be_nil()

                local delete_command = {
                    type = ops.COMMAND_TYPES.DELETE_WORKFLOW,
                    payload = {
                        dataflow_id = delete_dataflow_id
                    }
                }

                local result, err = ops.execute(tx, delete_dataflow_id, nil, delete_command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].dataflow_id).to_equal(delete_dataflow_id)
                expect(result.results[1].deleted).to_be_true()

                local count_query = "SELECT COUNT(*) AS wf_count FROM dataflows WHERE dataflow_id = ?"

                local deleted_rows, deleted_err = tx:query(count_query, { delete_dataflow_id })
                expect(deleted_err).to_be_nil()
                expect(deleted_rows[1].wf_count).to_equal(0)

                local context_rows, context_count_err = tx:query(count_query, { context_dataflow_id })
                expect(context_count_err).to_be_nil()
                expect(context_rows[1].wf_count).to_equal(1)
            end)
        end)

        describe("Node Operations", function()
            it("should add a node using CREATE_NODE command with minimal fields", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local node_id = uuid.v7()
                local command = {
                    type = ops.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = node_id,
                        node_type = "minimal_node_type"
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.op_id).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(node_id)

                local query = "SELECT * FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].node_id).to_equal(node_id)
                expect(rows[1].type).to_equal("minimal_node_type")
                expect(rows[1].status).to_equal("pending")
                expect(rows[1].parent_node_id).to_be_nil()

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(next(metadata)).to_be_nil()

                local config = json.decode(rows[1].config)
                expect(config).to_be_type("table")
                expect(next(config)).to_be_nil()
            end)

            it("should add a node using CREATE_NODE command with all optional fields", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local node_id = uuid.v7()
                local command = {
                    type = ops.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = node_id,
                        parent_node_id = resources.node_id,
                        node_type = "full_node_type",
                        status = "ready",
                        config = { timeout = 30, retries = 3, mode = "strict" },
                        metadata = { source = "ops_test", purpose = "testing", count = 42 }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.op_id).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(node_id)

                local query = "SELECT * FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].node_id).to_equal(node_id)
                expect(rows[1].parent_node_id).to_equal(resources.node_id)
                expect(rows[1].type).to_equal("full_node_type")
                expect(rows[1].status).to_equal("ready")

                local config = json.decode(rows[1].config)
                expect(config).to_be_type("table")
                expect(config.timeout).to_equal(30)
                expect(config.retries).to_equal(3)
                expect(config.mode).to_equal("strict")

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(metadata.source).to_equal("ops_test")
                expect(metadata.purpose).to_equal("testing")
                expect(metadata.count).to_equal(42)
            end)

            it("should add a node with config as pre-encoded JSON string", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local node_id = uuid.v7()
                local config_json_string = '{"batch_size":100,"parallel":true,"settings":{"debug":false}}'
                local command = {
                    type = ops.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = node_id,
                        node_type = "json_config_node",
                        config = config_json_string
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(node_id)

                local query = "SELECT config FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)

                local config = json.decode(rows[1].config)
                expect(config).to_be_type("table")
                expect(config.batch_size).to_equal(100)
                expect(config.parallel).to_be_true()
                expect(config.settings).to_be_type("table")
                expect(config.settings.debug).to_be_false()
            end)

            it("should fail to add a node without required node_type", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local node_id = uuid.v7()
                local command = {
                    type = ops.COMMAND_TYPES.CREATE_NODE,
                    payload = {
                        node_id = node_id
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Node type is required")

                local query = "SELECT COUNT(*) AS node_count FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { node_id })

                expect(err_query).to_be_nil()
                expect(rows[1].node_count).to_equal(0)
            end)

            it("should update node config with UPDATE_NODE command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local initial_query = "SELECT config FROM nodes WHERE node_id = ?"
                local initial_rows, err_initial = tx:query(initial_query, { resources.node_id })

                expect(err_initial).to_be_nil()
                expect(#initial_rows).to_equal(1)

                local initial_config = json.decode(initial_rows[1].config)
                expect(initial_config).to_be_type("table")
                expect(next(initial_config)).to_be_nil()

                local command = {
                    type = ops.COMMAND_TYPES.UPDATE_NODE,
                    payload = {
                        node_id = resources.node_id,
                        config = {
                            max_workers = 4,
                            timeout = 60,
                            features = { "logging", "metrics" }
                        }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(resources.node_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT config FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { resources.node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)

                local config = json.decode(rows[1].config)
                expect(config).to_be_type("table")
                expect(config.max_workers).to_equal(4)
                expect(config.timeout).to_equal(60)
                expect(config.features).to_be_type("table")
                expect(#config.features).to_equal(2)
                expect(config.features[1]).to_equal("logging")
                expect(config.features[2]).to_equal("metrics")
            end)

            it("should update node metadata with UPDATE_NODE command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local initial_query = "SELECT metadata FROM nodes WHERE node_id = ?"
                local initial_rows, err_initial = tx:query(initial_query, { resources.node_id })

                expect(err_initial).to_be_nil()
                expect(#initial_rows).to_equal(1)

                local initial_metadata = json.decode(initial_rows[1].metadata)
                expect(initial_metadata).to_be_type("table")
                expect(next(initial_metadata)).to_be_nil()

                local command = {
                    type = ops.COMMAND_TYPES.UPDATE_NODE,
                    payload = {
                        node_id = resources.node_id,
                        metadata = {
                            updated = true,
                            version = 2,
                            tags = { "test", "update" }
                        }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(resources.node_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT metadata FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { resources.node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(metadata.updated).to_be_true()
                expect(metadata.version).to_equal(2)
                expect(metadata.tags).to_be_type("table")
                expect(#metadata.tags).to_equal(2)
                expect(metadata.tags[1]).to_equal("test")
                expect(metadata.tags[2]).to_equal("update")
            end)

            it("should update node status with UPDATE_NODE command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local initial_query = "SELECT status FROM nodes WHERE node_id = ?"
                local initial_rows, err_initial = tx:query(initial_query, { resources.node_id })

                expect(err_initial).to_be_nil()
                expect(#initial_rows).to_equal(1)
                expect(initial_rows[1].status).to_equal("pending")

                local command = {
                    type = ops.COMMAND_TYPES.UPDATE_NODE,
                    payload = {
                        node_id = resources.node_id,
                        status = "running"
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(resources.node_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT status FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { resources.node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].status).to_equal("running")
            end)

            it("should update node type with UPDATE_NODE command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local initial_query = "SELECT type FROM nodes WHERE node_id = ?"
                local initial_rows, err_initial = tx:query(initial_query, { resources.node_id })

                expect(err_initial).to_be_nil()
                expect(#initial_rows).to_equal(1)
                expect(initial_rows[1].type).to_equal("test_node")

                local command = {
                    type = ops.COMMAND_TYPES.UPDATE_NODE,
                    payload = {
                        node_id = resources.node_id,
                        node_type = "updated_node_type"
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(resources.node_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT type FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { resources.node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].type).to_equal("updated_node_type")
            end)

            it("should update multiple node fields including config with a single UPDATE_NODE command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local command = {
                    type = ops.COMMAND_TYPES.UPDATE_NODE,
                    payload = {
                        node_id = resources.node_id,
                        node_type = "multi_update_type",
                        status = "running",
                        config = { workers = 8, enabled = true },
                        metadata = { updated = true, multi = "field_update" }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(resources.node_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT * FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { resources.node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].type).to_equal("multi_update_type")
                expect(rows[1].status).to_equal("running")

                local config = json.decode(rows[1].config)
                expect(config).to_be_type("table")
                expect(config.workers).to_equal(8)
                expect(config.enabled).to_be_true()

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(metadata.updated).to_be_true()
                expect(metadata.multi).to_equal("field_update")
            end)

            it("should update config as pre-encoded JSON string with UPDATE_NODE command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local config_json_string = '{"api_key":"secret123","endpoints":["api.example.com"],"retry_count":5}'
                local command = {
                    type = ops.COMMAND_TYPES.UPDATE_NODE,
                    payload = {
                        node_id = resources.node_id,
                        config = config_json_string
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(resources.node_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT config FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { resources.node_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)

                local config = json.decode(rows[1].config)
                expect(config).to_be_type("table")
                expect(config.api_key).to_equal("secret123")
                expect(config.endpoints).to_be_type("table")
                expect(#config.endpoints).to_equal(1)
                expect(config.endpoints[1]).to_equal("api.example.com")
                expect(config.retry_count).to_equal(5)
            end)

            it("should handle empty updates with UPDATE_NODE command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local command = {
                    type = ops.COMMAND_TYPES.UPDATE_NODE,
                    payload = {
                        node_id = resources.node_id
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_false()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(resources.node_id)
                expect(result.results[1].changes_made).to_be_false()
                expect(result.results[1].message).to_contain("No fields provided for update")
            end)

            it("should delete a node with DELETE_NODE command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local initial_query = "SELECT 1 AS exists_flag FROM nodes WHERE node_id = ?"
                local initial_rows, err_initial = tx:query(initial_query, { resources.node_id })

                expect(err_initial).to_be_nil()
                expect(#initial_rows).to_equal(1)
                expect(initial_rows[1].exists_flag).to_equal(1)

                local command = {
                    type = ops.COMMAND_TYPES.DELETE_NODE,
                    payload = {
                        node_id = resources.node_id
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].node_id).to_equal(resources.node_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT COUNT(*) AS node_count FROM nodes WHERE node_id = ?"
                local rows, err_query = tx:query(query, { resources.node_id })

                expect(err_query).to_be_nil()
                expect(rows[1].node_count).to_equal(0)
            end)
        end)

        describe("Data Operations", function()
            it("should create data using CREATE_DATA command with minimal fields", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local data_id = uuid.v7()
                local command = {
                    type = ops.COMMAND_TYPES.CREATE_DATA,
                    payload = {
                        data_id = data_id,
                        data_type = "test_data",
                        key = "minimal_test_key",
                        content = "Simple string content"
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.op_id).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].data_id).to_equal(data_id)

                local query = "SELECT * FROM data WHERE data_id = ?"
                local rows, err_query = tx:query(query, { data_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].data_id).to_equal(data_id)
                expect(rows[1].dataflow_id).to_equal(resources.dataflow_id)
                expect(rows[1].node_id).to_be_nil()
                expect(rows[1].type).to_equal("test_data")
                expect(rows[1].discriminator).to_equal(nil)
                expect(rows[1].key).to_equal("minimal_test_key")
                expect(rows[1].content).to_equal("Simple string content")
                expect(rows[1].content_type).to_equal("application/json")
            end)

            it("should create data with complex content and metadata", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local data_id = uuid.v7()
                local content_obj = {
                    items = {
                        { id = 1, name = "First item" },
                        { id = 2, name = "Second item" }
                    },
                    count = 2,
                    valid = true
                }
                local metadata_obj = {
                    source = "test",
                    created_by = "ops_test",
                    tags = { "complex", "data" }
                }

                local command = {
                    type = ops.COMMAND_TYPES.CREATE_DATA,
                    payload = {
                        data_id = data_id,
                        data_type = "complex_data",
                        key = "complex_test_key",
                        discriminator = "test_discriminator",
                        content = content_obj,
                        content_type = "application/json",
                        metadata = metadata_obj,
                        node_id = resources.node_id
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].data_id).to_equal(data_id)

                local query = "SELECT * FROM data WHERE data_id = ?"
                local rows, err_query = tx:query(query, { data_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)
                expect(rows[1].data_id).to_equal(data_id)
                expect(rows[1].dataflow_id).to_equal(resources.dataflow_id)
                expect(rows[1].node_id).to_equal(resources.node_id)
                expect(rows[1].type).to_equal("complex_data")
                expect(rows[1].discriminator).to_equal("test_discriminator")
                expect(rows[1].key).to_equal("complex_test_key")
                expect(rows[1].content_type).to_equal("application/json")

                local content = json.decode(rows[1].content)
                expect(content).to_be_type("table")
                expect(content.count).to_equal(2)
                expect(content.valid).to_be_true()
                expect(#content.items).to_equal(2)
                expect(content.items[1].id).to_equal(1)
                expect(content.items[2].name).to_equal("Second item")

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(metadata.source).to_equal("test")
                expect(metadata.created_by).to_equal("ops_test")
                expect(#metadata.tags).to_equal(2)
            end)

            it("should update data content with UPDATE_DATA command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local data_id = uuid.v7()
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_DATA,
                    payload = {
                        data_id = data_id,
                        data_type = "updatable_data",
                        key = "update_test_key",
                        content = { value = "original value", count = 1 }
                    }
                }

                local create_result, err_create = ops.execute(tx, resources.dataflow_id, nil, create_command)
                expect(err_create).to_be_nil()
                expect(create_result.changes_made).to_be_true()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_DATA,
                    payload = {
                        data_id = data_id,
                        content = { value = "updated value", count = 2, new_field = true }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].data_id).to_equal(data_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT content FROM data WHERE data_id = ?"
                local rows, err_query = tx:query(query, { data_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)

                local content = json.decode(rows[1].content)
                expect(content).to_be_type("table")
                expect(content.value).to_equal("updated value")
                expect(content.count).to_equal(2)
                expect(content.new_field).to_be_true()
            end)

            it("should update data metadata with UPDATE_DATA command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local data_id = uuid.v7()
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_DATA,
                    payload = {
                        data_id = data_id,
                        data_type = "updatable_data",
                        key = "metadata_update_test",
                        content = "Test content",
                        metadata = { version = 1 }
                    }
                }

                local create_result, err_create = ops.execute(tx, resources.dataflow_id, nil, create_command)
                expect(err_create).to_be_nil()
                expect(create_result.changes_made).to_be_true()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_DATA,
                    payload = {
                        data_id = data_id,
                        metadata = { version = 2, updated = true, tags = { "modified" } }
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].data_id).to_equal(data_id)
                expect(result.results[1].changes_made).to_be_true()

                local query = "SELECT metadata FROM data WHERE data_id = ?"
                local rows, err_query = tx:query(query, { data_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(metadata.version).to_equal(2)
                expect(metadata.updated).to_be_true()
                expect(metadata.tags).to_be_type("table")
                expect(#metadata.tags).to_equal(1)
                expect(metadata.tags[1]).to_equal("modified")
            end)

            it("should delete data with DELETE_DATA command", function()
                local resources = setup_test_resources()
                local tx = get_test_transaction()

                local data_id = uuid.v7()
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_DATA,
                    payload = {
                        data_id = data_id,
                        data_type = "deletable_data",
                        key = "delete_test_key",
                        content = "Content to be deleted"
                    }
                }

                local create_result, err_create = ops.execute(tx, resources.dataflow_id, nil, create_command)
                expect(err_create).to_be_nil()
                expect(create_result.changes_made).to_be_true()

                local exists_query = "SELECT COUNT(*) AS data_count FROM data WHERE data_id = ?"
                local exists_rows, err_exists = tx:query(exists_query, { data_id })
                expect(err_exists).to_be_nil()
                expect(exists_rows[1].data_count).to_equal(1)

                local delete_command = {
                    type = ops.COMMAND_TYPES.DELETE_DATA,
                    payload = {
                        data_id = data_id
                    }
                }

                local result, err = ops.execute(tx, resources.dataflow_id, nil, delete_command)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(#result.results).to_equal(1)
                expect(result.results[1].data_id).to_equal(data_id)
                expect(result.results[1].changes_made).to_be_true()

                local count_query = "SELECT COUNT(*) AS data_count FROM data WHERE data_id = ?"
                local count_rows, count_err = tx:query(count_query, { data_id })
                expect(count_err).to_be_nil()
                expect(count_rows[1].data_count).to_equal(0)
            end)
        end)

        describe("Metadata Handling", function()
            it("should merge metadata by default when updating workflow", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                -- Create workflow with initial metadata
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "merge_test_type",
                        metadata = {
                            title = "Original Title",
                            version = 1,
                            tags = { "initial", "test" }
                        }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                -- Update with new metadata (should merge by default)
                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = {
                            status = "running",
                            version = 2,
                            started_at = "2024-01-01T12:00:00Z"
                        }
                        -- merge_metadata not specified, should default to true
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(result.results[1].metadata_merged).to_be_true()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                expect(#rows).to_equal(1)

                local metadata = json.decode(rows[1].metadata)
                -- Original metadata should be preserved
                expect(metadata.title).to_equal("Original Title")
                expect(metadata.tags).to_be_type("table")
                expect(#metadata.tags).to_equal(2)
                expect(metadata.tags[1]).to_equal("initial")
                -- New metadata should be added
                expect(metadata.status).to_equal("running")
                expect(metadata.started_at).to_equal("2024-01-01T12:00:00Z")
                -- Overlapping key should be updated
                expect(metadata.version).to_equal(2)
            end)

            it("should merge metadata when explicitly requested", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "explicit_merge_test",
                        metadata = {
                            priority = "high",
                            department = "engineering",
                            config = { timeout = 30 }
                        }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = {
                            priority = "urgent",     -- Should overwrite
                            assignee = "john.doe",   -- Should add
                            config = { retries = 3 } -- Should overwrite completely
                        },
                        merge_metadata = true        -- Explicit merge
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(result.results[1].metadata_merged).to_be_true()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                local metadata = json.decode(rows[1].metadata)

                expect(metadata.priority).to_equal("urgent")        -- Overwritten
                expect(metadata.department).to_equal("engineering") -- Preserved
                expect(metadata.assignee).to_equal("john.doe")      -- Added
                expect(metadata.config.retries).to_equal(3)         -- New config
                expect(metadata.config.timeout).to_be_nil()         -- Original config overwritten
            end)

            it("should replace metadata when explicitly disabled", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "replace_test",
                        metadata = {
                            original_field = "original_value",
                            preserve_me = "should_be_lost",
                            nested = { keep = "nope" }
                        }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = {
                            new_field = "new_value",
                            replacement = true
                        },
                        merge_metadata = false -- Explicit replacement
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(result.results[1].metadata_merged).to_be_false()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                local metadata = json.decode(rows[1].metadata)

                -- Only new metadata should exist
                expect(metadata.new_field).to_equal("new_value")
                expect(metadata.replacement).to_be_true()
                -- Original metadata should be gone
                expect(metadata.original_field).to_be_nil()
                expect(metadata.preserve_me).to_be_nil()
                expect(metadata.nested).to_be_nil()
            end)

            it("should handle empty existing metadata during merge", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                -- Create workflow with empty metadata
                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "empty_meta_test"
                        -- No metadata provided
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = {
                            first_addition = "value1",
                            nested = { key = "value" }
                        },
                        merge_metadata = true
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                local metadata = json.decode(rows[1].metadata)

                expect(metadata.first_addition).to_equal("value1")
                expect(metadata.nested.key).to_equal("value")
            end)

            it("should handle empty update metadata during merge", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "empty_update_test",
                        metadata = {
                            preserved_field = "should_remain",
                            count = 42
                        }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = {}, -- Empty metadata update
                        merge_metadata = true
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                local metadata = json.decode(rows[1].metadata)

                -- Original metadata should be preserved
                expect(metadata.preserved_field).to_equal("should_remain")
                expect(metadata.count).to_equal(42)
            end)

            it("should handle JSON string metadata during merge", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "json_string_test",
                        metadata = '{"string_created":"true","num":123}'
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = '{"string_updated":"true","num":456,"new_field":"added"}',
                        merge_metadata = true
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                local metadata = json.decode(rows[1].metadata)

                expect(metadata.string_created).to_equal("true") -- Preserved
                expect(metadata.string_updated).to_equal("true") -- Added
                expect(metadata.num).to_equal(456)               -- Overwritten
                expect(metadata.new_field).to_equal("added")     -- Added
            end)

            it("should fail gracefully with malformed JSON during merge", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "malformed_json_test",
                        metadata = { valid = "metadata" }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = '{"malformed":json}', -- Invalid JSON
                        merge_metadata = true
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(result).to_be_nil()
                expect(err).to_contain("Failed to decode new metadata JSON")
            end)

            it("should preserve complex nested structures during merge", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "complex_merge_test",
                        metadata = {
                            config = {
                                database = { host = "localhost", port = 5432 },
                                features = { "logging", "metrics" }
                            },
                            owner = "team-alpha"
                        }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = {
                            config = {
                                cache = { ttl = 300 },
                                features = { "caching" } -- Will overwrite arrays completely
                            },
                            status = "active"
                        },
                        merge_metadata = true
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                local metadata = json.decode(rows[1].metadata)

                -- Top-level merge behavior
                expect(metadata.owner).to_equal("team-alpha") -- Preserved
                expect(metadata.status).to_equal("active")    -- Added

                -- Nested objects are replaced entirely (Lua table merge behavior)
                expect(metadata.config.cache.ttl).to_equal(300) -- From update
                expect(metadata.config.database).to_be_nil()    -- Lost in merge
                expect(#metadata.config.features).to_equal(1)   -- Replaced
                expect(metadata.config.features[1]).to_equal("caching")
            end)

            it("should clear metadata with empty object replacement", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "clear_test",
                        metadata = { should_be_cleared = "value", count = 42 }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        metadata = {}, -- Clear with empty object
                        merge_metadata = false -- Use replacement
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()

                local query = "SELECT metadata FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()

                local metadata = json.decode(rows[1].metadata)
                expect(metadata).to_be_type("table")
                expect(next(metadata)).to_be_nil() -- Should be empty table
            end)

            it("should maintain backward compatibility with existing UPDATE_WORKFLOW usage", function()
                local tx = get_test_transaction()

                local dataflow_id = uuid.v7()
                local actor_id = "test-actor-" .. uuid.v7()

                local create_command = {
                    type = ops.COMMAND_TYPES.CREATE_WORKFLOW,
                    payload = {
                        dataflow_id = dataflow_id,
                        actor_id = actor_id,
                        type = "backward_compat_test",
                        metadata = { original = "data" }
                    }
                }

                local create_result, create_err = ops.execute(tx, dataflow_id, nil, create_command)
                expect(create_err).to_be_nil()

                -- Old-style update without merge_metadata flag
                local update_command = {
                    type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
                    payload = {
                        status = "completed",
                        metadata = { completion_time = "2024-01-01" }
                        -- No merge_metadata specified - should default to merge=true
                    }
                }

                local result, err = ops.execute(tx, dataflow_id, nil, update_command)

                expect(err).to_be_nil()
                expect(result.changes_made).to_be_true()
                expect(result.results[1].metadata_merged).to_be_true() -- Default behavior

                local query = "SELECT metadata, status FROM dataflows WHERE dataflow_id = ?"
                local rows, err_query = tx:query(query, { dataflow_id })

                expect(err_query).to_be_nil()
                expect(rows[1].status).to_equal("completed")

                local metadata = json.decode(rows[1].metadata)
                expect(metadata.original).to_equal("data") -- Should be preserved with new default
                expect(metadata.completion_time).to_equal("2024-01-01")
            end)
        end)
    end)
end

return test.run_cases(define_tests)
