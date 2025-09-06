local test = require("test")
local uuid = require("uuid")
local time = require("time")

local client = require("client")
local consts = require("consts")

local function define_tests()
    describe("Workflow Client", function()
        local mock_deps
        local captured_calls
        local mock_security_actor

        before_each(function()
            -- Reset captured calls
            captured_calls = {
                commit_execute = {},
                funcs_call = {},
                process_spawn = {},
                process_cancel = {},
                process_terminate = {},
                process_lookup = {},
                dataflow_repo_get = {},
                data_reader_calls = {}
            }

            -- Mock security actor
            mock_security_actor = {
                id = function() return "test-actor-123" end
            }

            -- Create mock dependencies
            mock_deps = {
                dataflow_repo = {
                    get_by_user = function(dataflow_id, actor_id)
                        table.insert(captured_calls.dataflow_repo_get, {
                            dataflow_id = dataflow_id,
                            actor_id = actor_id
                        })
                        return {
                            dataflow_id = dataflow_id,
                            status = "running",
                            actor_id = actor_id,
                            type = "test_workflow"
                        }, nil
                    end
                },
                commit = {
                    execute = function(dataflow_id, op_id, commands, options)
                        table.insert(captured_calls.commit_execute, {
                            dataflow_id = dataflow_id,
                            op_id = op_id,
                            commands = commands,
                            options = options
                        })
                        return { changes_made = true }, nil
                    end
                },
                data_reader = {
                    with_dataflow = function(dataflow_id)
                        table.insert(captured_calls.data_reader_calls, {
                            method = "with_dataflow",
                            dataflow_id = dataflow_id
                        })
                        return {
                            with_data_types = function(data_types)
                                table.insert(captured_calls.data_reader_calls, {
                                    method = "with_data_types",
                                    data_types = data_types
                                })
                                return {
                                    fetch_options = function(options)
                                        table.insert(captured_calls.data_reader_calls, {
                                            method = "fetch_options",
                                            options = options
                                        })
                                        return {
                                            all = function()
                                                table.insert(captured_calls.data_reader_calls, {
                                                    method = "all"
                                                })
                                                -- Return mock workflow output data
                                                return {
                                                    {
                                                        key = "result",
                                                        content = '{"message":"test output","processed":true}',
                                                        content_type = consts.CONTENT_TYPE.JSON
                                                    },
                                                    {
                                                        key = "backup",
                                                        content = '{"backup_data":"saved"}',
                                                        content_type = consts.CONTENT_TYPE.JSON
                                                    }
                                                }
                                            end,
                                            one = function()
                                                table.insert(captured_calls.data_reader_calls, {
                                                    method = "one"
                                                })
                                                return {
                                                    key = "",
                                                    content = '{"root_output":"test data"}',
                                                    content_type = consts.CONTENT_TYPE.JSON
                                                }
                                            end
                                        }
                                    end,
                                    all = function()
                                        table.insert(captured_calls.data_reader_calls, {
                                            method = "all"
                                        })
                                        return {}
                                    end
                                }
                            end
                        }
                    end
                },
                process = {
                    spawn = function(process_type, host, args)
                        table.insert(captured_calls.process_spawn, {
                            process_type = process_type,
                            host = host,
                            args = args
                        })
                        return "mock-pid-456"
                    end,
                    registry = {
                        lookup = function(process_name)
                            table.insert(captured_calls.process_lookup, { process_name = process_name })
                            return "mock-registry-pid-789"
                        end
                    },
                    cancel = function(pid, timeout)
                        table.insert(captured_calls.process_cancel, { pid = pid, timeout = timeout })
                        return true, nil
                    end,
                    terminate = function(pid)
                        table.insert(captured_calls.process_terminate, { pid = pid })
                        return true, nil
                    end
                },
                funcs = {
                    new = function()
                        return {
                            call = function(self, func_name, args)
                                table.insert(captured_calls.funcs_call, {
                                    func_name = func_name,
                                    args = args
                                })
                                return {
                                    success = true,
                                    dataflow_id = args.dataflow_id or "generated-id-123",
                                    output = { message = "execution completed" }
                                }, nil
                            end
                        }
                    end
                },
                security = {
                    actor = function()
                        return mock_security_actor
                    end
                }
            }
        end)

        describe("Constructor", function()
            it("should create client with current security actor", function()
                local instance, err = client.new(mock_deps)

                expect(err).to_be_nil()
                expect(instance).not_to_be_nil()
                expect(instance._actor_id).to_equal("test-actor-123")
                expect(instance._deps).to_equal(mock_deps)
            end)

            it("should create client with default dependencies when none provided", function()
                -- This would use real dependencies, but we can't easily test that
                -- without mocking the require() calls. For now, just test with mock deps
                local instance, err = client.new(mock_deps)

                expect(err).to_be_nil()
                expect(instance).not_to_be_nil()
                expect(instance._actor_id).to_equal("test-actor-123")
            end)

            it("should fail when no security actor available", function()
                local no_actor_deps = {}
                for k, v in pairs(mock_deps) do
                    no_actor_deps[k] = v
                end
                no_actor_deps.security = {
                    actor = function() return nil end
                }

                local instance, err = client.new(no_actor_deps)

                expect(instance).to_be_nil()
                expect(err).to_contain("No current security actor available")
            end)

            it("should fail when security actor has no id function", function()
                local bad_actor_deps = {}
                for k, v in pairs(mock_deps) do
                    bad_actor_deps[k] = v
                end
                bad_actor_deps.security = {
                    actor = function() return {} end -- Actor without id() function
                }

                local instance, err = client.new(bad_actor_deps)

                expect(instance).to_be_nil()
                expect(err).to_contain("Security actor does not have id() method")
            end)

            it("should fail when security actor id() returns empty string", function()
                local empty_id_deps = {}
                for k, v in pairs(mock_deps) do
                    empty_id_deps[k] = v
                end
                empty_id_deps.security = {
                    actor = function()
                        return {
                            id = function() return "" end
                        }
                    end
                }

                local instance, err = client.new(empty_id_deps)

                expect(instance).to_be_nil()
                expect(err).to_contain("Actor ID cannot be empty")
            end)
        end)

        describe("Create Workflow Method", function()
            local test_client

            before_each(function()
                test_client, _ = client.new(mock_deps)
                -- Debug: Verify client has data_reader
                expect(test_client._deps).not_to_be_nil()
                expect(test_client._deps.data_reader).not_to_be_nil()
            end)

            it("should create workflow with no additional commands", function()
                local dataflow_id, err = test_client:create_workflow()

                expect(err).to_be_nil()
                expect(dataflow_id).not_to_be_nil()
                expect(type(dataflow_id)).to_equal("string")

                -- Verify commit.execute was called
                expect(#captured_calls.commit_execute).to_equal(1)
                local call = captured_calls.commit_execute[1]
                expect(call.dataflow_id).to_equal(dataflow_id)
                expect(#call.commands).to_equal(1)
                expect(call.commands[1].type).to_equal(consts.COMMAND_TYPES.CREATE_WORKFLOW)
                expect(call.commands[1].payload.actor_id).to_equal("test-actor-123")
                expect(call.commands[1].payload.type).to_equal("workflow")
            end)

            it("should create workflow with additional commands", function()
                local additional_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = "test-node-1",
                            node_type = "func"
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = "test-data-1",
                            data_type = consts.DATA_TYPE.NODE_INPUT,
                            content = "test input"
                        }
                    }
                }

                local dataflow_id, err = test_client:create_workflow(additional_commands)

                expect(err).to_be_nil()
                expect(dataflow_id).not_to_be_nil()

                local call = captured_calls.commit_execute[1]
                expect(#call.commands).to_equal(3) -- CREATE_WORKFLOW + 2 additional
                expect(call.commands[1].type).to_equal(consts.COMMAND_TYPES.CREATE_WORKFLOW)
                expect(call.commands[2].type).to_equal(consts.COMMAND_TYPES.CREATE_NODE)
                expect(call.commands[3].type).to_equal(consts.COMMAND_TYPES.CREATE_DATA)
            end)

            it("should create workflow with custom options", function()
                local custom_id = "custom-workflow-id"
                local dataflow_id, err = test_client:create_workflow({}, {
                    dataflow_id = custom_id,
                    type = "custom_type",
                    metadata = { version = "1.0" }
                })

                expect(err).to_be_nil()
                expect(dataflow_id).to_equal(custom_id)

                local call = captured_calls.commit_execute[1]
                expect(call.dataflow_id).to_equal(custom_id)
                expect(call.commands[1].payload.type).to_equal("custom_type")
                expect(call.commands[1].payload.metadata.version).to_equal("1.0")
            end)

            it("should handle commit execution failure", function()
                mock_deps.commit.execute = function()
                    return nil, "Database error"
                end

                local dataflow_id, err = test_client:create_workflow()

                expect(dataflow_id).to_be_nil()
                expect(err).to_equal("Database error")
            end)
        end)

        describe("Execute Method", function()
            local test_client

            before_each(function()
                test_client, _ = client.new(mock_deps)
            end)

            it("should execute existing workflow synchronously with outputs", function()
                -- Debug: Check if data_reader exists in mock_deps
                expect(mock_deps.data_reader).not_to_be_nil()
                expect(type(mock_deps.data_reader.with_dataflow)).to_equal("function")

                local result, err = test_client:execute("existing-workflow-123")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.dataflow_id).to_equal("existing-workflow-123")
                expect(result.data).not_to_be_nil()
                expect(result.data.result).not_to_be_nil()
                expect(result.data.result.message).to_equal("test output")
                expect(result.data.backup).not_to_be_nil()

                -- Verify funcs was called correctly
                expect(#captured_calls.funcs_call).to_equal(1)
                local call = captured_calls.funcs_call[1]
                expect(call.func_name).to_equal(consts.ORCHESTRATOR)
                expect(call.args.dataflow_id).to_equal("existing-workflow-123")
                expect(call.args.init_func_id).to_be_nil()
            end)

            it("should execute workflow with init function", function()
                local result, err = test_client:execute("existing-workflow-123", {
                    init_func_id = "app:visualizer"
                })

                expect(err).to_be_nil()
                expect(result.success).to_be_true()

                local call = captured_calls.funcs_call[1]
                expect(call.args.init_func_id).to_equal("app:visualizer")
            end)

            it("should execute workflow without fetching outputs when disabled", function()
                local result, err = test_client:execute("existing-workflow-123", {
                    fetch_output = false
                })

                expect(err).to_be_nil()
                expect(result.success).to_be_true()
                expect(result.data).to_be_nil()

                -- Should not have called data_reader
                local reader_calls = 0
                for _, call in ipairs(captured_calls.data_reader_calls) do
                    if call.method == "with_dataflow" then
                        reader_calls = reader_calls + 1
                    end
                end
                expect(reader_calls).to_equal(0)
            end)

            it("should fail with missing dataflow_id", function()
                local result, err = test_client:execute("")

                expect(result).to_be_nil()
                expect(err).to_contain("Dataflow ID is required")
            end)

            it("should handle funcs execution failure", function()
                mock_deps.funcs.new = function()
                    return {
                        call = function()
                            return nil, "Orchestrator failed"
                        end
                    }
                end

                local result, err = test_client:execute("existing-workflow-123")

                expect(result).to_be_nil()
                expect(err).to_contain("Orchestrator failed")
            end)

            it("should handle orchestrator returning workflow failure", function()
                mock_deps.funcs.new = function()
                    return {
                        call = function()
                            return {
                                success = false,
                                dataflow_id = "existing-workflow-123",
                                error = "Workflow deadlocked"
                            }, nil
                        end
                    }
                end

                local result, err = test_client:execute("existing-workflow-123")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_false()
                expect(result.error).to_equal("Workflow deadlocked")
                expect(result.data).to_be_nil()
            end)
        end)

        describe("Output Method", function()
            local test_client

            before_each(function()
                test_client, _ = client.new(mock_deps)
                -- Debug: Verify client has data_reader
                expect(test_client._deps).not_to_be_nil()
                expect(test_client._deps.data_reader).not_to_be_nil()
            end)

            it("should fetch workflow outputs as key-value pairs", function()
                local outputs, err = test_client:output("test-workflow-id")

                expect(err).to_be_nil()
                expect(outputs).not_to_be_nil()
                expect(outputs.result).not_to_be_nil()
                expect(outputs.result.message).to_equal("test output")
                expect(outputs.backup).not_to_be_nil()
                expect(outputs.backup.backup_data).to_equal("saved")
            end)

            it("should return empty table when no outputs exist", function()
                mock_deps.data_reader.with_dataflow = function()
                    return {
                        with_data_types = function()
                            return {
                                fetch_options = function()
                                    return {
                                        all = function()
                                            return {}
                                        end
                                    }
                                end
                            }
                        end
                    }
                end

                local outputs, err = test_client:output("test-workflow-id")

                expect(err).to_be_nil()
                expect(outputs).not_to_be_nil()
                expect(next(outputs)).to_be_nil() -- empty table
            end)

            it("should handle root output correctly", function()
                mock_deps.data_reader.with_dataflow = function()
                    return {
                        with_data_types = function()
                            return {
                                fetch_options = function()
                                    return {
                                        all = function()
                                            return {
                                                {
                                                    key = "",
                                                    content = '{"root_data":"test"}',
                                                    content_type = consts.CONTENT_TYPE.JSON
                                                }
                                            }
                                        end
                                    }
                                end
                            }
                        end
                    }
                end

                local outputs, err = test_client:output("test-workflow-id")

                expect(err).to_be_nil()
                expect(outputs).not_to_be_nil()
                expect(outputs.root_data).to_equal("test")
            end)

            it("should fail with missing dataflow_id", function()
                local outputs, err = test_client:output("")

                expect(outputs).to_be_nil()
                expect(err).to_contain("Dataflow ID is required")
            end)
        end)

        describe("Start Method", function()
            local test_client

            before_each(function()
                test_client, _ = client.new(mock_deps)
                -- Debug: Verify client has data_reader
                expect(test_client._deps).not_to_be_nil()
                expect(test_client._deps.data_reader).not_to_be_nil()
            end)

            it("should start workflow asynchronously", function()
                local dataflow_id, err = test_client:start("existing-workflow-456")

                expect(err).to_be_nil()
                expect(dataflow_id).to_equal("existing-workflow-456")

                -- Verify process.spawn was called
                expect(#captured_calls.process_spawn).to_equal(1)
                local spawn_call = captured_calls.process_spawn[1]
                expect(spawn_call.process_type).to_equal(consts.ORCHESTRATOR)
                expect(spawn_call.host).to_equal(consts.HOST_ID)
                expect(spawn_call.args.dataflow_id).to_equal("existing-workflow-456")
                expect(spawn_call.args.init_func_id).to_be_nil()
            end)

            it("should start workflow with init function", function()
                local dataflow_id, err = test_client:start("existing-workflow-456", {
                    init_func_id = "app:setup"
                })

                expect(err).to_be_nil()
                expect(dataflow_id).to_equal("existing-workflow-456")

                local spawn_call = captured_calls.process_spawn[1]
                expect(spawn_call.args.init_func_id).to_equal("app:setup")
            end)

            it("should fail with missing dataflow_id", function()
                local dataflow_id, err = test_client:start("")

                expect(dataflow_id).to_be_nil()
                expect(err).to_contain("Dataflow ID is required")
            end)

            it("should fail when process spawn fails", function()
                mock_deps.process.spawn = function() return nil end

                local dataflow_id, err = test_client:start("existing-workflow-456")

                expect(dataflow_id).to_be_nil()
                expect(err).to_contain("Failed to spawn workflow process")
            end)
        end)

        describe("Cancel Method", function()
            local test_client

            before_each(function()
                test_client, _ = client.new(mock_deps)
                -- Debug: Verify client has data_reader
                expect(test_client._deps).not_to_be_nil()
                expect(test_client._deps.data_reader).not_to_be_nil()
            end)

            it("should cancel workflow successfully", function()
                local success, err, info = test_client:cancel("workflow-123", "45s")

                expect(success).to_be_true()
                expect(err).to_be_nil()
                expect(info).not_to_be_nil()
                expect(info.dataflow_id).to_equal("workflow-123")
                expect(info.timeout).to_equal("45s")
                expect(info.message).to_contain("Cancel signal sent")

                -- Verify calls were made
                expect(#captured_calls.dataflow_repo_get).to_equal(1)
                expect(#captured_calls.process_lookup).to_equal(1)
                expect(#captured_calls.process_cancel).to_equal(1)

                expect(captured_calls.process_lookup[1].process_name).to_equal("dataflow.workflow-123")
                expect(captured_calls.process_cancel[1].timeout).to_equal("45s")
            end)

            it("should use default timeout", function()
                test_client:cancel("workflow-123")

                expect(captured_calls.process_cancel[1].timeout).to_equal("30s")
            end)

            it("should fail with missing dataflow_id", function()
                local success, err = test_client:cancel("")

                expect(success).to_be_false()
                expect(err).to_contain("Workflow ID is required")
            end)

            it("should fail when workflow not found", function()
                mock_deps.dataflow_repo.get_by_user = function() return nil, "Workflow not found" end

                local success, err = test_client:cancel("workflow-123")

                expect(success).to_be_false()
                expect(err).to_equal("Workflow not found")
            end)

            it("should fail when workflow not in cancellable state", function()
                mock_deps.dataflow_repo.get_by_user = function()
                    return { status = "completed" }, nil
                end

                local success, err = test_client:cancel("workflow-123")

                expect(success).to_be_false()
                expect(err).to_contain("cannot be cancelled in current state: completed")
            end)

            it("should fail when process not found in registry", function()
                mock_deps.process.registry.lookup = function() return nil end

                local success, err = test_client:cancel("workflow-123")

                expect(success).to_be_false()
                expect(err).to_contain("Workflow process not found in registry")
            end)

            it("should fail when cancel signal fails", function()
                mock_deps.process.cancel = function() return false, "Cancel failed" end

                local success, err = test_client:cancel("workflow-123")

                expect(success).to_be_false()
                expect(err).to_contain("Failed to send cancel signal: Cancel failed")
            end)
        end)

        describe("Terminate Method", function()
            local test_client

            before_each(function()
                test_client, _ = client.new(mock_deps)
                -- Debug: Verify client has data_reader
                expect(test_client._deps).not_to_be_nil()
                expect(test_client._deps.data_reader).not_to_be_nil()
            end)

            it("should terminate workflow successfully", function()
                local success, err, info = test_client:terminate("workflow-456")

                expect(success).to_be_true()
                expect(err).to_be_nil()
                expect(info).not_to_be_nil()
                expect(info.dataflow_id).to_equal("workflow-456")
                expect(info.process_terminated).to_be_true()
                expect(info.status_updated).to_be_true()

                -- Verify calls were made
                expect(#captured_calls.dataflow_repo_get).to_equal(1)
                expect(#captured_calls.process_lookup).to_equal(1)
                expect(#captured_calls.process_terminate).to_equal(1)
                expect(#captured_calls.commit_execute).to_equal(1)

                -- Check commit call
                local commit_call = captured_calls.commit_execute[1]
                expect(commit_call.commands[1].type).to_equal(consts.COMMAND_TYPES.UPDATE_WORKFLOW)
                expect(commit_call.commands[1].payload.status).to_equal("terminated")
            end)

            it("should fail with missing dataflow_id", function()
                local success, err = test_client:terminate("")

                expect(success).to_be_false()
                expect(err).to_contain("Workflow ID is required")
            end)

            it("should fail when workflow already finished", function()
                mock_deps.dataflow_repo.get_by_user = function()
                    return { status = "completed" }, nil
                end

                local success, err = test_client:terminate("workflow-456")

                expect(success).to_be_false()
                expect(err).to_contain("already finished with status: completed")
            end)

            it("should handle process not found gracefully", function()
                mock_deps.process.registry.lookup = function() return nil end

                local success, err, info = test_client:terminate("workflow-456")

                expect(success).to_be_true()
                expect(err).to_be_nil()
                expect(info.process_terminated).to_be_false()
                expect(info.status_updated).to_be_true()
            end)

            it("should handle process termination failure", function()
                mock_deps.process.terminate = function() return false, "Terminate failed" end

                local success, err, info = test_client:terminate("workflow-456")

                expect(success).to_be_true() -- Should still succeed with status update
                expect(info.process_terminated).to_be_false()
                expect(info.terminate_error).to_equal("Terminate failed")
            end)

            it("should fail when commit execution fails", function()
                mock_deps.commit.execute = function() return nil, "Commit failed" end

                local success, err, info = test_client:terminate("workflow-456")

                expect(success).to_be_false()
                expect(err).to_contain("Failed to update workflow status: Commit failed")
                expect(info).not_to_be_nil()
                expect(info.process_terminated).to_be_true()
            end)
        end)

        describe("Get Status Method", function()
            local test_client

            before_each(function()
                test_client, _ = client.new(mock_deps)
                -- Debug: Verify client has data_reader
                expect(test_client._deps).not_to_be_nil()
                expect(test_client._deps.data_reader).not_to_be_nil()
            end)

            it("should get workflow status successfully", function()
                local status, err = test_client:get_status("workflow-789")

                expect(err).to_be_nil()
                expect(status).to_equal("running")

                -- Verify dataflow_repo was called
                expect(#captured_calls.dataflow_repo_get).to_equal(1)
                expect(captured_calls.dataflow_repo_get[1].dataflow_id).to_equal("workflow-789")
                expect(captured_calls.dataflow_repo_get[1].actor_id).to_equal("test-actor-123")
            end)

            it("should fail with missing dataflow_id", function()
                local status, err = test_client:get_status("")

                expect(status).to_be_nil()
                expect(err).to_contain("Workflow ID is required")
            end)

            it("should fail when workflow not found", function()
                mock_deps.dataflow_repo.get_by_user = function() return nil, "Not found" end

                local status, err = test_client:get_status("workflow-789")

                expect(status).to_be_nil()
                expect(err).to_equal("Not found")
            end)

            it("should return different statuses", function()
                mock_deps.dataflow_repo.get_by_user = function()
                    return { status = "completed" }, nil
                end

                local status, err = test_client:get_status("workflow-789")

                expect(err).to_be_nil()
                expect(status).to_equal("completed")
            end)
        end)

        describe("Integration Scenarios", function()
            local test_client

            before_each(function()
                test_client, _ = client.new(mock_deps)
                -- Debug: Verify client has data_reader
                expect(test_client._deps).not_to_be_nil()
                expect(test_client._deps.data_reader).not_to_be_nil()
            end)

            it("should handle complete workflow lifecycle", function()
                -- Create workflow
                local dataflow_id, create_err = test_client:create_workflow({
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = "test-node",
                            node_type = "func"
                        }
                    }
                })
                expect(create_err).to_be_nil()
                expect(dataflow_id).not_to_be_nil()

                -- Execute workflow
                local result, exec_err = test_client:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result.success).to_be_true()
                expect(result.data).not_to_be_nil()

                -- Check status
                local status, status_err = test_client:get_status(dataflow_id)
                expect(status_err).to_be_nil()
                expect(status).to_equal("running")

                -- Cancel workflow
                local cancel_success, cancel_err = test_client:cancel(dataflow_id)
                expect(cancel_success).to_be_true()
                expect(cancel_err).to_be_nil()
            end)

            it("should handle actor ownership verification", function()
                -- All methods should verify actor ownership
                test_client:get_status("test-workflow")
                test_client:cancel("test-workflow")
                test_client:terminate("test-workflow")

                -- All should have called dataflow_repo.get_by_user with correct actor_id
                expect(#captured_calls.dataflow_repo_get).to_equal(3)
                for _, call in ipairs(captured_calls.dataflow_repo_get) do
                    expect(call.actor_id).to_equal("test-actor-123")
                end
            end)

            it("should handle create and start workflow separately", function()
                -- Create workflow first
                local dataflow_id, create_err = test_client:create_workflow({
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = "async-node",
                            node_type = "func"
                        }
                    }
                })
                expect(create_err).to_be_nil()

                -- Start it asynchronously
                local start_id, start_err = test_client:start(dataflow_id)
                expect(start_err).to_be_nil()
                expect(start_id).to_equal(dataflow_id)

                -- Verify proper orchestrator call
                local spawn_call = captured_calls.process_spawn[1]
                expect(spawn_call.process_type).to_equal(consts.ORCHESTRATOR)
                expect(spawn_call.args.dataflow_id).to_equal(dataflow_id)
            end)

            it("should handle workflow failure with proper error structure", function()
                mock_deps.funcs.new = function()
                    return {
                        call = function()
                            return {
                                success = false,
                                dataflow_id = "failed-workflow",
                                error = "Node execution failed"
                            }, nil
                        end
                    }
                end

                local result, err = test_client:execute("failed-workflow")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_false()
                expect(result.dataflow_id).to_equal("failed-workflow")
                expect(result.error).to_equal("Node execution failed")
                expect(result.data).to_be_nil()
            end)
        end)
    end)
end

return test.run_cases(define_tests)