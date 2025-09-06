local test = require("test")
local uuid = require("uuid")
local json = require("json")
local consts = require("consts")
local iterator = require("iterator")

local function define_tests()
    describe("Iterator Tests", function()
        describe("Single Iteration Creation", function()
            it("should create iteration with simple template graph", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent",
                    path = { "ancestor1", "ancestor2" },
                    command = function(self, cmd)
                        -- Mock command function
                        self._commands = self._commands or {}
                        table.insert(self._commands, cmd)
                    end,
                    data = function(self, data_type, content, options)
                        -- Mock data function
                        self._data_calls = self._data_calls or {}
                        table.insert(self._data_calls, {
                            data_type = data_type,
                            content = content,
                            options = options
                        })
                    end
                }

                local template_graph = {
                    nodes = {
                        ["template1"] = {
                            node_id = "template1",
                            type = "func_node",
                            config = {},
                            metadata = {
                                title = "Test Function Node",
                                description = "A test node for validation"
                            }
                        }
                    },
                    get_roots = function(self)
                        return { "template1" }
                    end
                }

                local input_item = { message = "test", value = 42 }
                local iteration_index = 1
                local iteration_input_key = "default"

                local iteration_info = iterator.create_iteration(
                    parent_node, template_graph, input_item, iteration_index, iteration_input_key
                )

                expect(iteration_info.iteration).to_equal(1)
                expect(iteration_info.input_item).to_equal(input_item)
                expect(iteration_info.uuid_mapping).not_to_be_nil()
                expect(iteration_info.uuid_mapping["template1"]).not_to_be_nil()
                expect(#iteration_info.root_nodes).to_equal(1)

                -- Fix: Compare individual elements instead of table reference
                expect(#iteration_info.child_path).to_equal(3)
                expect(iteration_info.child_path[1]).to_equal("ancestor1")
                expect(iteration_info.child_path[2]).to_equal("ancestor2")
                expect(iteration_info.child_path[3]).to_equal("parent")

                -- Verify command was called to create node
                expect(parent_node._commands).not_to_be_nil()
                expect(#parent_node._commands).to_equal(1)
                expect(parent_node._commands[1].type).to_equal(consts.COMMAND_TYPES.CREATE_NODE)

                -- Verify metadata preservation and title enhancement
                local created_node = parent_node._commands[1].payload
                expect(created_node.metadata).not_to_be_nil()
                expect(created_node.metadata.title).to_equal("Test Function Node (#1)")
                expect(created_node.metadata.description).to_equal("A test node for validation")
                expect(created_node.metadata.iteration).to_equal(1)
                expect(created_node.metadata.template_source).to_equal("template1")

                -- Verify data was called to create input
                expect(parent_node._data_calls).not_to_be_nil()
                expect(#parent_node._data_calls).to_equal(1)
                expect(parent_node._data_calls[1].data_type).to_equal(consts.DATA_TYPE.NODE_INPUT)
            end)

            it("should handle templates without metadata", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent",
                    path = {},
                    command = function(self, cmd)
                        self._commands = self._commands or {}
                        table.insert(self._commands, cmd)
                    end,
                    data = function(self, data_type, content, options)
                        self._data_calls = self._data_calls or {}
                        table.insert(self._data_calls, {
                            data_type = data_type,
                            content = content,
                            options = options
                        })
                    end
                }

                local template_graph = {
                    nodes = {
                        ["template1"] = {
                            node_id = "template1",
                            type = "func_node",
                            config = {}
                            -- No metadata field
                        }
                    },
                    get_roots = function(self)
                        return { "template1" }
                    end
                }

                local iteration_info = iterator.create_iteration(
                    parent_node, template_graph, { test = "data" }, 2, "default"
                )

                expect(iteration_info.iteration).to_equal(2)

                -- Verify minimal metadata is created
                local created_node = parent_node._commands[1].payload
                expect(created_node.metadata).not_to_be_nil()
                expect(created_node.metadata.title).to_be_nil() -- No original title
                expect(created_node.metadata.iteration).to_equal(2)
                expect(created_node.metadata.template_source).to_equal("template1")
            end)

            it("should handle templates with metadata but no title", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent",
                    path = {},
                    command = function(self, cmd)
                        self._commands = self._commands or {}
                        table.insert(self._commands, cmd)
                    end,
                    data = function(self, data_type, content, options)
                        self._data_calls = self._data_calls or {}
                        table.insert(self._data_calls, {
                            data_type = data_type,
                            content = content,
                            options = options
                        })
                    end
                }

                local template_graph = {
                    nodes = {
                        ["template1"] = {
                            node_id = "template1",
                            type = "func_node",
                            config = {},
                            metadata = {
                                description = "A node without title",
                                custom_field = "custom_value"
                            }
                        }
                    },
                    get_roots = function(self)
                        return { "template1" }
                    end
                }

                local iteration_info = iterator.create_iteration(
                    parent_node, template_graph, { test = "data" }, 3, "default"
                )

                expect(iteration_info.iteration).to_equal(3)

                -- Verify metadata preservation without title modification
                local created_node = parent_node._commands[1].payload
                expect(created_node.metadata).not_to_be_nil()
                expect(created_node.metadata.title).to_be_nil() -- No title to modify
                expect(created_node.metadata.description).to_equal("A node without title")
                expect(created_node.metadata.custom_field).to_equal("custom_value")
                expect(created_node.metadata.iteration).to_equal(3)
                expect(created_node.metadata.template_source).to_equal("template1")
            end)

            it("should handle multiple templates with dependencies", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent",
                    path = {},
                    command = function(self, cmd)
                        self._commands = self._commands or {}
                        table.insert(self._commands, cmd)
                    end,
                    data = function(self, data_type, content, options)
                        self._data_calls = self._data_calls or {}
                        table.insert(self._data_calls, {
                            data_type = data_type,
                            content = content,
                            options = options
                        })
                    end
                }

                local template_graph = {
                    nodes = {
                        ["template1"] = {
                            node_id = "template1",
                            type = "func_node",
                            config = {
                                data_targets = {
                                    {
                                        data_type = "node.input",
                                        node_id = "template2"
                                    }
                                }
                            },
                            metadata = {
                                title = "First Node",
                                order = 1
                            }
                        },
                        ["template2"] = {
                            node_id = "template2",
                            type = "func_node",
                            config = {},
                            metadata = {
                                title = "Second Node",
                                order = 2
                            }
                        }
                    },
                    get_roots = function(self)
                        return { "template1" }
                    end
                }

                local input_item = { data = "test" }
                local iteration_info = iterator.create_iteration(
                    parent_node, template_graph, input_item, 4, "default"
                )

                expect(#iteration_info.root_nodes).to_equal(1)
                expect(parent_node._commands).not_to_be_nil()
                expect(#parent_node._commands).to_equal(2) -- Two nodes created
                expect(#parent_node._data_calls).to_equal(1) -- Only root gets input

                -- Verify UUID remapping in config
                local template1_cmd = nil
                local template2_cmd = nil

                for _, cmd in ipairs(parent_node._commands) do
                    if cmd.payload.metadata.template_source == "template1" then
                        template1_cmd = cmd
                    elseif cmd.payload.metadata.template_source == "template2" then
                        template2_cmd = cmd
                    end
                end

                expect(template1_cmd).not_to_be_nil()
                expect(template2_cmd).not_to_be_nil()

                -- Verify title enhancement for both nodes
                expect(template1_cmd.payload.metadata.title).to_equal("First Node (#4)")
                expect(template1_cmd.payload.metadata.order).to_equal(1)
                expect(template2_cmd.payload.metadata.title).to_equal("Second Node (#4)")
                expect(template2_cmd.payload.metadata.order).to_equal(2)

                -- Verify UUID remapping
                local data_targets = template1_cmd.payload.config.data_targets
                expect(data_targets[1].node_id).to_equal(iteration_info.uuid_mapping["template2"])
            end)
        end)

        describe("Batch Creation", function()
            it("should create multiple iterations in batch", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent",
                    path = {},
                    command = function(self, cmd)
                        self._commands = self._commands or {}
                        table.insert(self._commands, cmd)
                    end,
                    data = function(self, data_type, content, options)
                        self._data_calls = self._data_calls or {}
                        table.insert(self._data_calls, {
                            data_type = data_type,
                            content = content,
                            options = options
                        })
                    end
                }

                local template_graph = {
                    nodes = {
                        ["template1"] = {
                            node_id = "template1",
                            type = "func_node",
                            config = {},
                            metadata = {
                                title = "Batch Processing Node"
                            }
                        }
                    },
                    get_roots = function(self)
                        return { "template1" }
                    end
                }

                local items = {
                    { id = 1, data = "first" },
                    { id = 2, data = "second" },
                    { id = 3, data = "third" }
                }

                local iterations, err = iterator.create_batch(
                    parent_node, template_graph, items, 1, 3, "default"
                )

                expect(err).to_be_nil()
                expect(iterations).not_to_be_nil()
                expect(#iterations).to_equal(3)

                for i, iteration in ipairs(iterations) do
                    expect(iteration.iteration).to_equal(i)
                    expect(iteration.input_item).to_equal(items[i])
                    expect(#iteration.root_nodes).to_equal(1)
                end

                -- Should have created 3 nodes (one per iteration)
                expect(#parent_node._commands).to_equal(3)
                expect(#parent_node._data_calls).to_equal(3)

                -- Verify title enhancement for each iteration
                for i, cmd in ipairs(parent_node._commands) do
                    expect(cmd.payload.metadata.title).to_equal("Batch Processing Node (#" .. i .. ")")
                    expect(cmd.payload.metadata.iteration).to_equal(i)
                end
            end)

            it("should handle partial batch range", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent",
                    path = {},
                    command = function(self, cmd)
                        self._commands = self._commands or {}
                        table.insert(self._commands, cmd)
                    end,
                    data = function(self, data_type, content, options)
                        self._data_calls = self._data_calls or {}
                        table.insert(self._data_calls, {
                            data_type = data_type,
                            content = content,
                            options = options
                        })
                    end
                }

                local template_graph = {
                    nodes = {
                        ["template1"] = {
                            node_id = "template1",
                            type = "func_node",
                            config = {},
                            metadata = {
                                title = "Partial Batch Node"
                            }
                        }
                    },
                    get_roots = function(self)
                        return { "template1" }
                    end
                }

                local items = { "a", "b", "c", "d", "e" }

                local iterations, err = iterator.create_batch(
                    parent_node, template_graph, items, 2, 4, "default"
                )

                expect(err).to_be_nil()
                expect(#iterations).to_equal(3) -- Items 2, 3, 4
                expect(iterations[1].iteration).to_equal(2)
                expect(iterations[2].iteration).to_equal(3)
                expect(iterations[3].iteration).to_equal(4)
                expect(iterations[1].input_item).to_equal("b")
                expect(iterations[2].input_item).to_equal("c")
                expect(iterations[3].input_item).to_equal("d")

                -- Verify correct iteration numbering in titles
                expect(parent_node._commands[1].payload.metadata.title).to_equal("Partial Batch Node (#2)")
                expect(parent_node._commands[2].payload.metadata.title).to_equal("Partial Batch Node (#3)")
                expect(parent_node._commands[3].payload.metadata.title).to_equal("Partial Batch Node (#4)")
            end)

            it("should validate batch parameters", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent"
                }

                local template_graph = {
                    nodes = {},
                    get_roots = function(self) return {} end
                }

                local iterations1, err1 = iterator.create_batch(nil, template_graph, {}, 1, 1, "default")
                expect(iterations1).to_be_nil()
                expect(err1).to_contain("Missing required parameters")

                local iterations2, err2 = iterator.create_batch(parent_node, template_graph, {}, 0, 1, "default")
                expect(iterations2).to_be_nil()
                expect(err2).to_contain("Invalid batch range")

                local iterations3, err3 = iterator.create_batch(parent_node, template_graph, {"a"}, 1, 2, "default")
                expect(iterations3).to_be_nil()
                expect(err3).to_contain("Invalid batch range")
            end)
        end)

        describe("Config Remapping", function()
            it("should remap data_targets node references", function()
                local config = {
                    func_id = "test_func",
                    data_targets = {
                        {
                            data_type = "node.input",
                            node_id = "template1"
                        },
                        {
                            data_type = "workflow.output",
                            key = "result"
                        }
                    }
                }

                local uuid_mapping = {
                    ["template1"] = "actual-node-123"
                }

                local remapped = iterator.remap_template_config(config, uuid_mapping)

                expect(remapped.func_id).to_equal("test_func")
                expect(#remapped.data_targets).to_equal(2)
                expect(remapped.data_targets[1].node_id).to_equal("actual-node-123")
                expect(remapped.data_targets[2].node_id).to_be_nil() -- Should not be affected
                expect(remapped.data_targets[2].key).to_equal("result")
            end)

            it("should remap error_targets node references", function()
                local config = {
                    error_targets = {
                        {
                            data_type = "node.input",
                            node_id = "template2"
                        }
                    }
                }

                local uuid_mapping = {
                    ["template2"] = "actual-node-456"
                }

                local remapped = iterator.remap_template_config(config, uuid_mapping)

                expect(#remapped.error_targets).to_equal(1)
                expect(remapped.error_targets[1].node_id).to_equal("actual-node-456")
            end)

            it("should handle nil config", function()
                local remapped = iterator.remap_template_config(nil, {})
                expect(remapped).to_be_type("table")
                expect(next(remapped)).to_be_nil() -- Empty table
            end)

            it("should preserve non-remappable references", function()
                local config = {
                    data_targets = {
                        {
                            data_type = "node.input",
                            node_id = "external-node" -- Not in mapping
                        }
                    }
                }

                local uuid_mapping = {
                    ["template1"] = "actual-node-123"
                }

                local remapped = iterator.remap_template_config(config, uuid_mapping)
                expect(remapped.data_targets[1].node_id).to_equal("external-node")
            end)
        end)

        describe("Result Collection", function()
            it("should collect results from iteration nodes", function()
                local parent_node = {
                    dataflow_id = "test-df"
                }

                local iteration_info = {
                    uuid_mapping = {
                        ["template1"] = "actual-node-1",
                        ["template2"] = "actual-node-2"
                    }
                }

                local mock_data_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_nodes = function(node_ids)
                                return {
                                    with_data_types = function(data_type)
                                        return {
                                            fetch_options = function(options)
                                                return {
                                                    all = function()
                                                        return {
                                                            {
                                                                key = "result",
                                                                content = { message = "success", value = 123 },
                                                                node_id = "actual-node-2",
                                                                discriminator = "success"
                                                            }
                                                        }, nil
                                                    end
                                                }
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { data_reader = mock_data_reader }

                local result, err = iterator.collect_results(parent_node, iteration_info, deps)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.message).to_equal("success")
                expect(result.value).to_equal(123)
            end)

            it("should handle multiple outputs", function()
                local parent_node = {
                    dataflow_id = "test-df"
                }

                local iteration_info = {
                    uuid_mapping = {
                        ["template1"] = "actual-node-1"
                    }
                }

                local mock_data_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_nodes = function(node_ids)
                                return {
                                    with_data_types = function(data_type)
                                        return {
                                            fetch_options = function(options)
                                                return {
                                                    all = function()
                                                        return {
                                                            {
                                                                key = "result1",
                                                                content = "first",
                                                                node_id = "actual-node-1",
                                                                discriminator = "success"
                                                            },
                                                            {
                                                                key = "result2",
                                                                content = "second",
                                                                node_id = "actual-node-1",
                                                                discriminator = "success"
                                                            }
                                                        }, nil
                                                    end
                                                }
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { data_reader = mock_data_reader }

                local result, err = iterator.collect_results(parent_node, iteration_info, deps)

                expect(err).to_be_nil()
                expect(result).to_be_type("table")
                expect(#result).to_equal(2)
                expect(result[1].content).to_equal("first")
                expect(result[2].content).to_equal("second")
            end)

            it("should handle data reader errors", function()
                local parent_node = {
                    dataflow_id = "test-df"
                }

                local iteration_info = {
                    uuid_mapping = { ["template1"] = "actual-node-1" }
                }

                local mock_data_reader = {
                    with_dataflow = function(dataflow_id)
                        return nil, "Database connection failed"
                    end
                }

                local deps = { data_reader = mock_data_reader }

                local result, err = iterator.collect_results(parent_node, iteration_info, deps)

                expect(result).to_be_nil()
                expect(err).to_contain("Failed to create data reader")
            end)

            it("should handle query errors", function()
                local parent_node = {
                    dataflow_id = "test-df"
                }

                local iteration_info = {
                    uuid_mapping = { ["template1"] = "actual-node-1" }
                }

                local mock_data_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_nodes = function(node_ids)
                                return {
                                    with_data_types = function(data_type)
                                        return {
                                            fetch_options = function(options)
                                                return {
                                                    all = function()
                                                        return nil, "Query execution failed"
                                                    end
                                                }
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { data_reader = mock_data_reader }

                local result, err = iterator.collect_results(parent_node, iteration_info, deps)

                expect(result).to_be_nil()
                expect(err).to_contain("Failed to query output data")
            end)

            it("should handle no output data", function()
                local parent_node = {
                    dataflow_id = "test-df"
                }

                local iteration_info = {
                    uuid_mapping = { ["template1"] = "actual-node-1" }
                }

                local mock_data_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_nodes = function(node_ids)
                                return {
                                    with_data_types = function(data_type)
                                        return {
                                            fetch_options = function(options)
                                                return {
                                                    all = function()
                                                        return {}, nil -- Empty results
                                                    end
                                                }
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { data_reader = mock_data_reader }

                local result, err = iterator.collect_results(parent_node, iteration_info, deps)

                expect(result).to_be_nil()
                expect(err).to_contain("No output data found")
            end)

            it("should parse JSON content correctly", function()
                local parent_node = {
                    dataflow_id = "test-df"
                }

                local iteration_info = {
                    uuid_mapping = { ["template1"] = "actual-node-1" }
                }

                local mock_data_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_nodes = function(node_ids)
                                return {
                                    with_data_types = function(data_type)
                                        return {
                                            fetch_options = function(options)
                                                return {
                                                    all = function()
                                                        return {
                                                            {
                                                                key = "result",
                                                                content = '{"message":"parsed","success":true}',
                                                                content_type = "application/json",
                                                                node_id = "actual-node-1",
                                                                discriminator = "success"
                                                            }
                                                        }, nil
                                                    end
                                                }
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { data_reader = mock_data_reader }

                local result, err = iterator.collect_results(parent_node, iteration_info, deps)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(type(result)).to_equal("table") -- Should be parsed as table
                expect(result.message).to_equal("parsed")
                expect(result.success).to_be_true()
            end)
        end)

        describe("Metadata Preservation Tests", function()
            it("should preserve all original metadata fields", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent",
                    path = {},
                    command = function(self, cmd)
                        self._commands = self._commands or {}
                        table.insert(self._commands, cmd)
                    end,
                    data = function(self, data_type, content, options) end
                }

                local template_graph = {
                    nodes = {
                        ["template1"] = {
                            node_id = "template1",
                            type = "func_node",
                            config = {},
                            metadata = {
                                title = "Complex Node",
                                description = "A node with lots of metadata",
                                version = "1.2.3",
                                author = "test_user",
                                tags = { "processing", "data" },
                                settings = {
                                    timeout = 30,
                                    retries = 3
                                },
                                custom_field = true
                            }
                        }
                    },
                    get_roots = function(self)
                        return { "template1" }
                    end
                }

                local iteration_info = iterator.create_iteration(
                    parent_node, template_graph, { test = "data" }, 5, "default"
                )

                local created_node = parent_node._commands[1].payload
                local metadata = created_node.metadata

                -- Verify all original metadata is preserved
                expect(metadata.title).to_equal("Complex Node (#5)")
                expect(metadata.description).to_equal("A node with lots of metadata")
                expect(metadata.version).to_equal("1.2.3")
                expect(metadata.author).to_equal("test_user")
                expect(#metadata.tags).to_equal(2)
                expect(metadata.tags[1]).to_equal("processing")
                expect(metadata.tags[2]).to_equal("data")
                expect(metadata.settings.timeout).to_equal(30)
                expect(metadata.settings.retries).to_equal(3)
                expect(metadata.custom_field).to_be_true()

                -- Verify iteration-specific metadata is added
                expect(metadata.iteration).to_equal(5)
                expect(metadata.template_source).to_equal("template1")
            end)

            it("should handle complex title scenarios", function()
                local parent_node = {
                    dataflow_id = "test-df",
                    node_id = "parent",
                    path = {},
                    command = function(self, cmd)
                        self._commands = self._commands or {}
                        table.insert(self._commands, cmd)
                    end,
                    data = function(self, data_type, content, options) end
                }

                local test_cases = {
                    {
                        original = "Simple Title",
                        iteration = 1,
                        expected = "Simple Title (#1)"
                    },
                    {
                        original = "Title with (parentheses)",
                        iteration = 42,
                        expected = "Title with (parentheses) (#42)"
                    },
                    {
                        original = "Title with #hash",
                        iteration = 7,
                        expected = "Title with #hash (#7)"
                    },
                    {
                        original = "",
                        iteration = 3,
                        expected = " (#3)"
                    }
                }

                for i, test_case in ipairs(test_cases) do
                    parent_node._commands = {} -- Reset commands

                    local template_graph = {
                        nodes = {
                            ["template1"] = {
                                node_id = "template1",
                                type = "func_node",
                                config = {},
                                metadata = {
                                    title = test_case.original
                                }
                            }
                        },
                        get_roots = function(self)
                            return { "template1" }
                        end
                    }

                    iterator.create_iteration(
                        parent_node, template_graph, { test = "data" }, test_case.iteration, "default"
                    )

                    local created_node = parent_node._commands[1].payload
                    expect(created_node.metadata.title).to_equal(test_case.expected)
                end
            end)
        end)
    end)
end

return test.run_cases(define_tests)