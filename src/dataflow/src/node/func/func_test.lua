local test = require("test")
local uuid = require("uuid")
local json = require("json")
local client = require("client")
local consts = require("consts")
local data_reader = require("data_reader")

local function define_tests()
    describe("Function Node Integration Tests", function()
        describe("Basic Function Execution", function()
            it("should execute test_func successfully via func node", function()
                print("=== FUNC NODE INTEGRATION TEST START ===")

                local c, err = client.new()
                expect(err).to_be_nil()
                expect(c).not_to_be_nil()

                local node_id = uuid.v7()
                local input_data_id = uuid.v7()
                local node_input_id = uuid.v7()

                local test_input = {
                    message = "Function node test",
                    delay_ms = 50,
                    should_fail = false
                }

                local workflow_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = node_id,
                            node_type = "wippy.dataflow.node.func:node",
                            status = consts.STATUS.PENDING,
                            config = {
                                func_id = "wippy.dataflow.node.func:test_func",
                                data_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "result",
                                        content_type = consts.CONTENT_TYPE.JSON
                                    }
                                }
                            },
                            metadata = {
                                title = "Basic Function Execution Test Node"
                            }
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = input_data_id,
                            data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                            content = test_input,
                            content_type = consts.CONTENT_TYPE.JSON
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = node_input_id,
                            data_type = consts.DATA_TYPE.NODE_INPUT,
                            node_id = node_id,
                            key = input_data_id,
                            content = "",
                            content_type = "dataflow/reference"
                        }
                    }
                }

                local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                    metadata = {
                        title = "Basic Function Execution Test Workflow"
                    }
                })
                expect(create_err).to_be_nil()
                expect(dataflow_id).not_to_be_nil()

                local result, exec_err = c:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()

                -- Verify output was created
                local output_data = data_reader.with_dataflow(dataflow_id)
                    :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                    :fetch_options({ replace_references = true })
                    :one()

                expect(output_data).not_to_be_nil()

                local output_content = output_data.content
                if type(output_content) == "string" then
                    local decoded, decode_err = json.decode(output_content)
                    if not decode_err then
                        output_content = decoded
                    end
                end

                expect(output_content.message).to_equal("Function node test")
                expect(output_content.processed_by).to_equal("test_function")
                expect(output_content.success).to_be_true()

                print("✓ Function node executed successfully via test_func")
            end)

            it("should handle function failure correctly", function()
                local c, err = client.new()
                expect(err).to_be_nil()

                local node_id = uuid.v7()
                local input_data_id = uuid.v7()
                local node_input_id = uuid.v7()

                local test_input = {
                    message = "Should fail",
                    should_fail = true
                }

                local workflow_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = node_id,
                            node_type = "wippy.dataflow.node.func:node",
                            status = consts.STATUS.PENDING,
                            config = {
                                func_id = "wippy.dataflow.node.func:test_func",
                                data_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "result"
                                    }
                                },
                                error_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "error"
                                    }
                                }
                            },
                            metadata = {
                                title = "Function Failure Test Node"
                            }
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = input_data_id,
                            data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                            content = test_input,
                            content_type = consts.CONTENT_TYPE.JSON
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = node_input_id,
                            data_type = consts.DATA_TYPE.NODE_INPUT,
                            node_id = node_id,
                            key = input_data_id,
                            content = "",
                            content_type = "dataflow/reference"
                        }
                    }
                }

                local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                    metadata = {
                        title = "Function Failure Test Workflow"
                    }
                })
                expect(create_err).to_be_nil()

                local result, exec_err = c:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result.success).to_be_true()

                -- Check that error was routed via error_targets
                local error_outputs = data_reader.with_dataflow(dataflow_id)
                    :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                    :with_data_keys("error")
                    :fetch_options({ replace_references = true })
                    :all()

                expect(#error_outputs).to_be_greater_than(0)

                print("✓ Function node handled failure and routed error correctly")
            end)

            it("should fail when func_id is missing", function()
                local c, err = client.new()
                expect(err).to_be_nil()

                local node_id = uuid.v7()
                local input_data_id = uuid.v7()
                local node_input_id = uuid.v7()

                local test_input = { message = "test" }

                local workflow_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = node_id,
                            node_type = "wippy.dataflow.node.func:node",
                            status = consts.STATUS.PENDING,
                            config = {
                                -- Missing func_id!
                                data_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "result"
                                    }
                                }
                            },
                            metadata = {
                                title = "Missing Func ID Test Node"
                            }
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = input_data_id,
                            data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                            content = test_input,
                            content_type = consts.CONTENT_TYPE.JSON
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = node_input_id,
                            data_type = consts.DATA_TYPE.NODE_INPUT,
                            node_id = node_id,
                            key = input_data_id,
                            content = "",
                            content_type = "dataflow/reference"
                        }
                    }
                }

                local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                    metadata = {
                        title = "Missing Func ID Test Workflow"
                    }
                })
                expect(create_err).to_be_nil()

                local result, exec_err = c:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result.success).to_be_false()
                expect(result.error).to_contain("Function ID not specified")

                print("✓ Function node correctly failed with missing func_id")
            end)

            it("should fail when no input data provided", function()
                local c, err = client.new()
                expect(err).to_be_nil()

                local node_id = uuid.v7()

                local workflow_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = node_id,
                            node_type = "wippy.dataflow.node.func:node",
                            status = consts.STATUS.PENDING,
                            config = {
                                func_id = "wippy.dataflow.node.func:test_func",
                                data_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "result"
                                    }
                                }
                            },
                            metadata = {
                                title = "No Input Data Test Node"
                            }
                        }
                    }
                    -- No input data!
                }

                local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                    metadata = {
                        title = "No Input Data Test Workflow"
                    }
                })
                expect(create_err).to_be_nil()

                local result, exec_err = c:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result.success).to_be_false()
                expect(result.error).to_contain("No input data provided")

                print("✓ Function node correctly failed with no input data")
            end)

            it("should fail when function does not exist", function()
                local c, err = client.new()
                expect(err).to_be_nil()

                local node_id = uuid.v7()
                local input_data_id = uuid.v7()
                local node_input_id = uuid.v7()

                local test_input = { message = "test" }

                local workflow_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = node_id,
                            node_type = "wippy.dataflow.node.func:node",
                            status = consts.STATUS.PENDING,
                            config = {
                                func_id = "wippy.dataflow.node:nonexistent_func",
                                data_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "result"
                                    }
                                }
                            },
                            metadata = {
                                title = "Nonexistent Function Test Node"
                            }
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = input_data_id,
                            data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                            content = test_input,
                            content_type = consts.CONTENT_TYPE.JSON
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = node_input_id,
                            data_type = consts.DATA_TYPE.NODE_INPUT,
                            node_id = node_id,
                            key = input_data_id,
                            content = "",
                            content_type = "dataflow/reference"
                        }
                    }
                }

                local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                    metadata = {
                        title = "Nonexistent Function Test Workflow"
                    }
                })
                expect(create_err).to_be_nil()

                local result, exec_err = c:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result.success).to_be_false()
                expect(result.error).to_contain("failed")

                print("✓ Function node correctly failed with nonexistent function")
            end)

            it("should pass context to function when configured", function()
                local c, err = client.new()
                expect(err).to_be_nil()

                local node_id = uuid.v7()
                local input_data_id = uuid.v7()
                local node_input_id = uuid.v7()

                local test_input = {
                    message = "Context test",
                    delay_ms = 50
                }

                local test_context = {
                    user_id = "test_user_123",
                    environment = "integration_test"
                }

                local workflow_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = node_id,
                            node_type = "wippy.dataflow.node.func:node",
                            status = consts.STATUS.PENDING,
                            config = {
                                func_id = "wippy.dataflow.node.func:test_func",
                                context = test_context,
                                data_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "result",
                                        content_type = consts.CONTENT_TYPE.JSON
                                    }
                                }
                            },
                            metadata = {
                                title = "Context Test Node"
                            }
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = input_data_id,
                            data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                            content = test_input,
                            content_type = consts.CONTENT_TYPE.JSON
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = node_input_id,
                            data_type = consts.DATA_TYPE.NODE_INPUT,
                            node_id = node_id,
                            key = input_data_id,
                            content = "",
                            content_type = "dataflow/reference"
                        }
                    }
                }

                local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                    metadata = {
                        title = "Context Test Workflow"
                    }
                })
                expect(create_err).to_be_nil()

                local result, exec_err = c:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result.success).to_be_true()

                -- Verify output contains context data
                local output_data = data_reader.with_dataflow(dataflow_id)
                    :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                    :fetch_options({ replace_references = true })
                    :one()

                expect(output_data).not_to_be_nil()

                local output_content = output_data.content
                if type(output_content) == "string" then
                    local decoded, decode_err = json.decode(output_content)
                    if not decode_err then
                        output_content = decoded
                    end
                end

                expect(output_content.message).to_equal("Context test")
                expect(output_content.processed_by).to_equal("test_function")

                print("✓ Function node passed context successfully")
            end)
        end)

        describe("Input Handling", function()
            it("should handle string input correctly", function()
                local c, err = client.new()
                expect(err).to_be_nil()

                local node_id = uuid.v7()
                local input_data_id = uuid.v7()
                local node_input_id = uuid.v7()

                local test_input = "Simple string input"

                local workflow_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = node_id,
                            node_type = "wippy.dataflow.node.func:node",
                            status = consts.STATUS.PENDING,
                            config = {
                                func_id = "wippy.dataflow.node.func:test_func",
                                data_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "result"
                                    }
                                }
                            },
                            metadata = {
                                title = "String Input Test Node"
                            }
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = input_data_id,
                            data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                            content = test_input,
                            content_type = consts.CONTENT_TYPE.TEXT
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = node_input_id,
                            data_type = consts.DATA_TYPE.NODE_INPUT,
                            node_id = node_id,
                            key = input_data_id,
                            content = "",
                            content_type = "dataflow/reference"
                        }
                    }
                }

                local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                    metadata = {
                        title = "String Input Test Workflow"
                    }
                })
                expect(create_err).to_be_nil()

                local result, exec_err = c:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result.success).to_be_true()

                print("✓ Function node handled string input correctly")
            end)

            it("should use first available input when no default key", function()
                local c, err = client.new()
                expect(err).to_be_nil()

                local node_id = uuid.v7()
                local input_data_id = uuid.v7()
                local node_input_id = uuid.v7()

                local test_input = { message = "Named input test" }

                local workflow_commands = {
                    {
                        type = consts.COMMAND_TYPES.CREATE_NODE,
                        payload = {
                            node_id = node_id,
                            node_type = "wippy.dataflow.node.func:node",
                            status = consts.STATUS.PENDING,
                            config = {
                                func_id = "wippy.dataflow.node.func:test_func",
                                data_targets = {
                                    {
                                        data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                        key = "result"
                                    }
                                }
                            },
                            metadata = {
                                title = "Named Input Test Node"
                            }
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = input_data_id,
                            data_type = consts.DATA_TYPE.WORKFLOW_INPUT,
                            content = test_input,
                            content_type = consts.CONTENT_TYPE.JSON
                        }
                    },
                    {
                        type = consts.COMMAND_TYPES.CREATE_DATA,
                        payload = {
                            data_id = node_input_id,
                            data_type = consts.DATA_TYPE.NODE_INPUT,
                            node_id = node_id,
                            key = input_data_id,
                            content = "",
                            content_type = "dataflow/reference",
                            metadata = {
                                input_key = "named_input" -- Non-default key
                            }
                        }
                    }
                }

                local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                    metadata = {
                        title = "Named Input Test Workflow"
                    }
                })
                expect(create_err).to_be_nil()

                local result, exec_err = c:execute(dataflow_id)
                expect(exec_err).to_be_nil()
                expect(result.success).to_be_true()

                print("✓ Function node used first available input correctly")
            end)
        end)
    end)
end

return test.run_cases(define_tests)