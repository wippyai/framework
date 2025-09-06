local test = require("test")
local uuid = require("uuid")
local json = require("json")
local time = require("time")

local node = require("node")
local consts = require("consts")

local function define_tests()
    describe("Node SDK with DI", function()
        local mock_deps
        local captured_calls

        before_each(function()
            -- Reset captured calls
            captured_calls = {
                commit_submit = {},
                process_send = {},
                process_listen = {},
                data_reader_calls = {}
            }

            -- Create mock dependencies
            mock_deps = {
                commit = {
                    submit = function(dataflow_id, op_id, commands)
                        table.insert(captured_calls.commit_submit, {
                            dataflow_id = dataflow_id,
                            op_id = op_id,
                            commands = commands
                        })
                        return { commit_id = uuid.v7() }, nil
                    end
                },
                data_reader = {
                    with_dataflow = function(dataflow_id)
                        table.insert(captured_calls.data_reader_calls, { method = "with_dataflow", dataflow_id = dataflow_id })
                        return {
                            with_nodes = function(node_id)
                                table.insert(captured_calls.data_reader_calls, { method = "with_nodes", node_id = node_id })
                                return {
                                    with_data_types = function(data_type)
                                        table.insert(captured_calls.data_reader_calls, { method = "with_data_types", data_type = data_type })
                                        return {
                                            fetch_options = function(options)
                                                table.insert(captured_calls.data_reader_calls, { method = "fetch_options", options = options })
                                                return {
                                                    all = function()
                                                        table.insert(captured_calls.data_reader_calls, { method = "all" })
                                                        -- Return test input data
                                                        return {
                                                            {
                                                                content = '{"message": "hello"}',
                                                                content_type = consts.CONTENT_TYPE.JSON,
                                                                key = "input1",
                                                                metadata = { source = "test" },
                                                                discriminator = "primary"
                                                            },
                                                            {
                                                                content = "plain text",
                                                                content_type = consts.CONTENT_TYPE.TEXT,
                                                                key = "input2",
                                                                metadata = {},
                                                                discriminator = nil
                                                            }
                                                        }
                                                    end
                                                }
                                            end
                                        }
                                    end
                                }
                            end
                        }
                    end
                },
                process = {
                    send = function(target, topic, payload)
                        table.insert(captured_calls.process_send, {
                            target = target,
                            topic = topic,
                            payload = payload
                        })
                        return true
                    end,
                    listen = function(topic)
                        table.insert(captured_calls.process_listen, { topic = topic })
                        return {
                            receive = function()
                                -- Return mock yield response for tests that need it
                                return {
                                    response_data = {
                                        run_node_results = {
                                            ["child-1"] = { status = "completed", output = "result1" }
                                        }
                                    }
                                }, true
                            end
                        }
                    end
                }
            }
        end)

        describe("Constructor", function()
            it("should create a node instance with required args", function()
                local args = {
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }

                local instance, err = node.new(args, mock_deps)

                expect(err).to_be_nil()
                expect(instance).not_to_be_nil()
                expect(instance.node_id).to_equal("test-node-123")
                expect(instance.dataflow_id).to_equal("test-dataflow-456")
                expect(instance._deps).to_equal(mock_deps)
            end)

            it("should fail with missing required args", function()
                local instance, err = node.new(nil, mock_deps)
                expect(instance).to_be_nil()
                expect(err).to_contain("Node args required")

                instance, err = node.new({}, mock_deps)
                expect(instance).to_be_nil()
                expect(err).to_contain("node_id and dataflow_id")
            end)

            it("should handle node configuration properly from config", function()
                local args = {
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456",
                    node = {
                        config = {
                            data_targets = { { data_type = "output", key = "result" } },
                            error_targets = { { data_type = "error", key = "failure" } },
                            timeout = 30,
                            retries = 3
                        },
                        metadata = { custom = "value" }
                    }
                }

                local instance, err = node.new(args, mock_deps)

                expect(err).to_be_nil()
                expect(instance).not_to_be_nil()
                expect(#instance.data_targets).to_equal(1)
                expect(#instance.error_targets).to_equal(1)
                expect(instance._metadata.custom).to_equal("value")
                expect(instance._config.timeout).to_equal(30)
                expect(instance._config.retries).to_equal(3)
            end)

            it("should handle empty or missing config gracefully", function()
                local args = {
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456",
                    node = {
                        metadata = { custom = "value" }
                    }
                }

                local instance, err = node.new(args, mock_deps)

                expect(err).to_be_nil()
                expect(instance).not_to_be_nil()
                expect(#instance.data_targets).to_equal(0)
                expect(#instance.error_targets).to_equal(0)
                expect(type(instance._config)).to_equal("table")
                expect(next(instance._config)).to_be_nil()
            end)
        end)

        describe("Config Accessor", function()
            it("should provide access to node config", function()
                local args = {
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456",
                    node = {
                        config = {
                            timeout = 30,
                            retries = 3,
                            api_endpoint = "https://api.example.com",
                            features = { "logging", "metrics" }
                        }
                    }
                }

                local instance, err = node.new(args, mock_deps)
                expect(err).to_be_nil()

                local config = instance:config()
                expect(config).not_to_be_nil()
                expect(config.timeout).to_equal(30)
                expect(config.retries).to_equal(3)
                expect(config.api_endpoint).to_equal("https://api.example.com")
                expect(type(config.features)).to_equal("table")
                expect(#config.features).to_equal(2)
                expect(config.features[1]).to_equal("logging")
                expect(config.features[2]).to_equal("metrics")
            end)

            it("should return empty config when none provided", function()
                local args = {
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }

                local instance, err = node.new(args, mock_deps)
                expect(err).to_be_nil()

                local config = instance:config()
                expect(config).not_to_be_nil()
                expect(type(config)).to_equal("table")
                expect(next(config)).to_be_nil()
            end)
        end)

        describe("Input Methods", function()
            local test_node

            before_each(function()
                test_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, mock_deps)
            end)

            it("should get all inputs as a map and cache them", function()
                local inputs = test_node:inputs()

                expect(inputs).not_to_be_nil()
                expect(inputs.input1).not_to_be_nil()
                expect(inputs.input1.content.message).to_equal("hello")
                expect(inputs.input2).not_to_be_nil()
                expect(inputs.input2.content).to_equal("plain text")

                -- Verify data_reader was called
                expect(#captured_calls.data_reader_calls).to_be_greater_than(0)

                -- Verify caching - second call shouldn't trigger data_reader again
                local call_count = #captured_calls.data_reader_calls
                local inputs2 = test_node:inputs()
                expect(inputs2).to_equal(inputs)
                expect(#captured_calls.data_reader_calls).to_equal(call_count)
            end)

            it("should get specific input by key", function()
                local input = test_node:input("input1")

                expect(input).not_to_be_nil()
                expect(input.content.message).to_equal("hello")
                expect(input.key).to_equal("input1")
                expect(input.discriminator).to_equal("primary")
            end)

            it("should fail when input key is missing", function()
                local success, err = pcall(function()
                    test_node:input(nil)
                end)

                expect(success).to_be_false()
                expect(err).to_contain("Input key is required")
            end)
        end)

        describe("Data and Metadata Methods", function()
            local test_node

            before_each(function()
                test_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, mock_deps)
            end)

            it("should create data with proper command queuing", function()
                local result = test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test" })

                expect(result).to_equal(test_node) -- Should return self for chaining
                expect(#test_node._queued_commands).to_equal(1)
                expect(test_node._queued_commands[1].type).to_equal(consts.COMMAND_TYPES.CREATE_DATA)
                expect(test_node._queued_commands[1].payload.data_type).to_equal(consts.DATA_TYPE.NODE_OUTPUT)
            end)

            it("should update metadata properly", function()
                local result = test_node:metadata({ key1 = "value1", key2 = "value2" })

                expect(result).to_equal(test_node)
                expect(test_node._metadata.key1).to_equal("value1")
                expect(test_node._metadata.key2).to_equal("value2")
                expect(#test_node._queued_commands).to_equal(1)
                expect(test_node._queued_commands[1].type).to_equal(consts.COMMAND_TYPES.UPDATE_NODE)
            end)

            it("should merge metadata without overwriting existing values", function()
                test_node._metadata = { existing = "value", shared = "original" }

                test_node:metadata({ shared = "updated", new_key = "new_value" })

                expect(test_node._metadata.existing).to_equal("value")
                expect(test_node._metadata.shared).to_equal("updated")
                expect(test_node._metadata.new_key).to_equal("new_value")
            end)

            it("should handle nil and empty metadata updates gracefully", function()
                test_node:metadata(nil)
                expect(#test_node._queued_commands).to_equal(0)

                test_node:metadata({})
                expect(#test_node._queued_commands).to_equal(1)
            end)

            it("should determine content type automatically", function()
                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test" })
                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, "plain text")

                expect(test_node._queued_commands[1].payload.content_type).to_equal(consts.CONTENT_TYPE.JSON)
                expect(test_node._queued_commands[2].payload.content_type).to_equal(consts.CONTENT_TYPE.TEXT)
            end)
        end)

        describe("Child Node Creation", function()
            local test_node

            before_each(function()
                test_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, mock_deps)
            end)

            it("should create child nodes with auto-generated IDs", function()
                local definitions = {
                    { node_type = "child_type_1" },
                    { node_type = "child_type_2" }
                }

                local child_ids, err = test_node:with_child_nodes(definitions)

                expect(err).to_be_nil()
                expect(child_ids).not_to_be_nil()
                expect(#child_ids).to_equal(2)
                expect(#test_node._queued_commands).to_equal(2)

                for i, cmd in ipairs(test_node._queued_commands) do
                    expect(cmd.type).to_equal(consts.COMMAND_TYPES.CREATE_NODE)
                    expect(cmd.payload.node_type).to_equal(definitions[i].node_type)
                    expect(cmd.payload.parent_node_id).to_equal("test-node-123")
                end
            end)

            it("should create child nodes with provided IDs and config", function()
                local definitions = {
                    {
                        node_id = "child-1",
                        node_type = "child_type_1",
                        config = { timeout = 60, retries = 5 }
                    },
                    {
                        node_id = "child-2",
                        node_type = "child_type_2",
                        config = { parallel = true }
                    }
                }

                local child_ids, err = test_node:with_child_nodes(definitions)

                expect(err).to_be_nil()
                expect(child_ids[1]).to_equal("child-1")
                expect(child_ids[2]).to_equal("child-2")

                -- Check that config is passed through
                expect(test_node._queued_commands[1].payload.config).not_to_be_nil()
                expect(test_node._queued_commands[1].payload.config.timeout).to_equal(60)
                expect(test_node._queued_commands[2].payload.config.parallel).to_be_true()
            end)

            it("should fail with invalid child definitions", function()
                local child_ids, err = test_node:with_child_nodes(nil)
                expect(child_ids).to_be_nil()
                expect(err).to_contain("Child definitions required")

                child_ids, err = test_node:with_child_nodes({ { node_type = nil } })
                expect(child_ids).to_be_nil()
                expect(err).to_contain("node_type")
            end)
        end)

        describe("Submit Functionality", function()
            local test_node

            before_each(function()
                test_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, mock_deps)
            end)

            it("should submit queued commands without yielding", function()
                -- Queue some commands first
                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test1" })
                test_node:metadata({ status = "processing" })
                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test2" })

                expect(#test_node._queued_commands).to_equal(3)

                local success, err = test_node:submit()

                expect(success).to_be_true()
                expect(err).to_be_nil()
                expect(#test_node._queued_commands).to_equal(0) -- Queue should be cleared

                -- Should call commit.submit once
                expect(#captured_calls.commit_submit).to_equal(1)
                expect(#captured_calls.commit_submit[1].commands).to_equal(3)

                -- Should NOT call process.send (no yield signal)
                expect(#captured_calls.process_send).to_equal(0)
            end)

            it("should handle empty queue gracefully", function()
                expect(#test_node._queued_commands).to_equal(0)

                local success, err = test_node:submit()

                expect(success).to_be_true()
                expect(err).to_be_nil()

                -- Should not call commit.submit for empty queue
                expect(#captured_calls.commit_submit).to_equal(0)
            end)

            it("should handle commit failures gracefully", function()
                -- Create failing dependencies
                local failing_deps = {
                    commit = {
                        submit = function()
                            return nil, "Database connection failed"
                        end
                    },
                    process = mock_deps.process,
                    data_reader = mock_deps.data_reader
                }

                local failing_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, failing_deps)

                -- Queue a command
                failing_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test" })
                expect(#failing_node._queued_commands).to_equal(1)

                local success, err = failing_node:submit()

                expect(success).to_be_false()
                expect(err).to_equal("Database connection failed")
                expect(#failing_node._queued_commands).to_equal(1) -- Queue should not be cleared on failure
            end)

            it("should be chainable after submit success", function()
                -- Queue and submit some commands
                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test1" })
                local success, err = test_node:submit()
                expect(success).to_be_true()
                expect(#test_node._queued_commands).to_equal(0)

                -- Should be able to queue more commands after submit
                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test2" })
                test_node:metadata({ status = "updated" })
                expect(#test_node._queued_commands).to_equal(2)

                success, err = test_node:submit()
                expect(success).to_be_true()
                expect(#test_node._queued_commands).to_equal(0)

                -- Should have called commit.submit twice
                expect(#captured_calls.commit_submit).to_equal(2)
            end)

            it("should preserve command order when submitting", function()
                test_node:data("type1", "content1")
                test_node:metadata({ key1 = "value1" })
                test_node:data("type2", "content2")

                local success, err = test_node:submit()
                expect(success).to_be_true()

                local submit_call = captured_calls.commit_submit[1]
                expect(#submit_call.commands).to_equal(3)
                expect(submit_call.commands[1].payload.data_type).to_equal("type1")
                expect(submit_call.commands[2].type).to_equal(consts.COMMAND_TYPES.UPDATE_NODE)
                expect(submit_call.commands[3].payload.data_type).to_equal("type2")
            end)

            it("should maintain dataflow_id and generate op_id correctly", function()
                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test" })

                local success, err = test_node:submit()
                expect(success).to_be_true()

                local submit_call = captured_calls.commit_submit[1]
                expect(submit_call.dataflow_id).to_equal("test-dataflow-456")
                expect(submit_call.op_id).not_to_be_nil()
                expect(type(submit_call.op_id)).to_equal("string")
                expect(string.len(submit_call.op_id)).to_be_greater_than(0)
            end)
        end)

        describe("Yield Functionality", function()
            local test_node

            before_each(function()
                test_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, mock_deps)
            end)

            it("should handle empty yield", function()
                local result, err = test_node:yield()

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(type(result)).to_equal("table")

                -- Should call commit.submit once
                expect(#captured_calls.commit_submit).to_equal(1)

                -- Should call process.send once for yield signal
                expect(#captured_calls.process_send).to_equal(1)
                expect(captured_calls.process_send[1].topic).to_equal(consts.MESSAGE_TOPIC.YIELD_REQUEST)
            end)

            it("should yield and wait for children", function()
                local result, err = test_node:yield({ run_nodes = { "child-1" } })

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result["child-1"]).not_to_be_nil()
                expect(result["child-1"].status).to_equal("completed")

                -- Should call commit.submit and process.send
                expect(#captured_calls.commit_submit).to_equal(1)
                expect(#captured_calls.process_send).to_equal(1)
            end)

            it("should create yield persistence record", function()
                test_node:yield()

                expect(#captured_calls.commit_submit).to_equal(1)
                local submit_call = captured_calls.commit_submit[1]
                expect(submit_call.commands).not_to_be_nil()
                expect(#submit_call.commands).to_equal(1)
                expect(submit_call.commands[1].type).to_equal(consts.COMMAND_TYPES.CREATE_DATA)
                expect(submit_call.commands[1].payload.data_type).to_equal(consts.DATA_TYPE.NODE_YIELD)
            end)

            it("should differ from submit in that it sends process signals", function()
                -- Test submit vs yield behavior difference
                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test" })

                -- Submit should not send process signals
                local success, err = test_node:submit()
                expect(success).to_be_true()
                expect(#captured_calls.process_send).to_equal(0)

                -- Reset and test yield
                captured_calls.process_send = {}
                captured_calls.commit_submit = {}

                test_node:data(consts.DATA_TYPE.NODE_OUTPUT, { message = "test2" })
                local result, yield_err = test_node:yield()

                expect(yield_err).to_be_nil()
                expect(#captured_calls.process_send).to_equal(1) -- Should send yield signal
                expect(captured_calls.process_send[1].topic).to_equal(consts.MESSAGE_TOPIC.YIELD_REQUEST)
            end)
        end)

        describe("Output and Error Routing", function()
            local test_node

            before_each(function()
                test_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456",
                    node = {
                        config = {
                            data_targets = {
                                { data_type = "output.result", key = "main" },
                                { data_type = "output.summary", key = "summary" }
                            },
                            error_targets = {
                                { data_type = "error.details", key = "error" },
                                { data_type = "error.summary", key = "summary" }
                            }
                        }
                    }
                }, mock_deps)
            end)

            it("should route outputs via data_targets from config on complete", function()
                local result = test_node:complete({ message = "success" })

                expect(result.success).to_be_true()

                expect(#captured_calls.commit_submit).to_equal(1)

                -- First call should have routing commands
                local first_submit = captured_calls.commit_submit[1]
                local data_commands = 0
                for _, cmd in ipairs(first_submit.commands) do
                    if cmd.type == consts.COMMAND_TYPES.CREATE_DATA then
                        data_commands = data_commands + 1
                    end
                end
                expect(data_commands).to_equal(2) -- Should have 2 data routing commands
            end)

            it("should route errors via error_targets from config on fail", function()
                local result = test_node:fail("Something went wrong")

                expect(result.success).to_be_false()
                expect(#captured_calls.commit_submit).to_equal(1)

                -- First call should have error routing commands
                local first_submit = captured_calls.commit_submit[1]
                local data_commands = 0
                for _, cmd in ipairs(first_submit.commands) do
                    if cmd.type == consts.COMMAND_TYPES.CREATE_DATA then
                        data_commands = data_commands + 1
                    end
                end
                expect(data_commands).to_equal(2) -- Should have 2 error routing commands
            end)

            it("should handle complete without output content", function()
                local test_node_no_targets, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, mock_deps)

                local result = test_node_no_targets:complete()

                expect(result.success).to_be_true()
                expect(result.message).to_contain("completed successfully")
            end)

            it("should handle metadata updates in complete/fail", function()
                test_node:complete(nil, "Custom message", { final_status = "success" })

                expect(test_node._metadata.status_message).to_equal("Custom message")
                expect(test_node._metadata.final_status).to_equal("success")
            end)

            it("should verify config-based targets are loaded correctly", function()
                -- Verify that data_targets and error_targets come from config
                expect(#test_node.data_targets).to_equal(2)
                expect(#test_node.error_targets).to_equal(2)
                expect(test_node.data_targets[1].data_type).to_equal("output.result")
                expect(test_node.error_targets[1].data_type).to_equal("error.details")

                -- Verify config accessor returns the same data
                local config = test_node:config()
                expect(#config.data_targets).to_equal(2)
                expect(#config.error_targets).to_equal(2)
            end)
        end)

        describe("Error Handling", function()
            local test_node
            local failing_deps

            before_each(function()
                test_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, mock_deps)

                -- Create failing dependencies for error tests
                failing_deps = {
                    commit = {
                        submit = function()
                            return nil, "Database connection failed"
                        end
                    },
                    process = {
                        send = function() return false end,
                        listen = function() return { receive = function() return nil, false end } end
                    },
                    data_reader = mock_deps.data_reader
                }
            end)

            it("should handle commit submission failures", function()
                local failing_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, failing_deps)

                local result, err = failing_node:yield()

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Failed to submit yield")
                expect(err).to_contain("Database connection failed")
            end)

            it("should handle process send failures", function()
                -- Create deps where commit succeeds but process.send fails
                local process_fail_deps = {
                    commit = mock_deps.commit, -- Use working commit
                    process = {
                        send = function() return false end,
                        listen = mock_deps.process.listen
                    },
                    data_reader = mock_deps.data_reader
                }

                local failing_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, process_fail_deps)

                local result, err = failing_node:yield()

                expect(result).to_be_nil()
                expect(err).to_contain("Failed to send yield signal")
            end)

            it("should handle yield channel failures", function()
                -- Create deps where commit and send succeed but channel fails
                local channel_fail_deps = {
                    commit = mock_deps.commit, -- Use working commit
                    process = {
                        send = mock_deps.process.send, -- Use working send
                        listen = function()
                            return {
                                receive = function() return nil, false end
                            }
                        end
                    },
                    data_reader = mock_deps.data_reader
                }

                local failing_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, channel_fail_deps)

                local result, err = failing_node:yield({ run_nodes = { "child-1" } })

                expect(result).to_be_nil()
                expect(err).to_contain("Yield channel closed")
            end)
        end)

        describe("Query Operations", function()
            local test_node

            before_each(function()
                test_node, _ = node.new({
                    node_id = "test-node-123",
                    dataflow_id = "test-dataflow-456"
                }, mock_deps)
            end)

            it("should handle query operations", function()
                local query_builder = test_node:query()

                expect(query_builder).not_to_be_nil()
                expect(type(query_builder.with_nodes)).to_equal("function")
            end)
        end)
    end)
end

return test.run_cases(define_tests)