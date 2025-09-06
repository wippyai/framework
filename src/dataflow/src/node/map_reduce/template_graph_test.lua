local test = require("test")
local uuid = require("uuid")
local consts = require("consts")
local template_graph = require("template_graph")

local function define_tests()
    describe("Template Graph Tests", function()
        describe("Empty Graph", function()
            it("should create empty graph", function()
                local graph = template_graph.new()
                expect(graph:is_empty()).to_be_true()
                expect(#graph:get_roots()).to_equal(0)
                expect(#graph:get_all_nodes()).to_equal(0)
            end)
        end)

        describe("Graph Operations", function()
            it("should manage nodes and edges", function()
                local graph = template_graph.new()

                local node_a = uuid.v7()
                local node_b = uuid.v7()

                graph.nodes[node_a] = { node_id = node_a, type = "test_type" }
                graph.nodes[node_b] = { node_id = node_b, type = "test_type" }
                graph.edges[node_a] = { node_b }
                graph.roots = { node_a }

                expect(graph:is_empty()).to_be_false()
                expect(#graph:get_all_nodes()).to_equal(2)
                expect(#graph:get_roots()).to_equal(1)
                expect(graph:get_node(node_a)).not_to_be_nil()
                expect(graph:get_edges(node_a)[1]).to_equal(node_b)
            end)
        end)

        describe("Cycle Detection", function()
            it("should detect no cycles in simple chain", function()
                local graph = template_graph.new()

                local node_a = uuid.v7()
                local node_b = uuid.v7()
                local node_c = uuid.v7()

                graph.nodes[node_a] = { node_id = node_a }
                graph.nodes[node_b] = { node_id = node_b }
                graph.nodes[node_c] = { node_id = node_c }
                graph.edges[node_a] = { node_b }
                graph.edges[node_b] = { node_c }
                graph.edges[node_c] = {}

                local has_cycle, cycle_desc = graph:has_cycles()
                expect(has_cycle).to_be_false()
                expect(cycle_desc).to_be_nil()
            end)

            it("should detect simple cycle", function()
                local graph = template_graph.new()

                local node_a = uuid.v7()
                local node_b = uuid.v7()

                graph.nodes[node_a] = { node_id = node_a }
                graph.nodes[node_b] = { node_id = node_b }
                graph.edges[node_a] = { node_b }
                graph.edges[node_b] = { node_a }

                local has_cycle, cycle_desc = graph:has_cycles()
                expect(has_cycle).to_be_true()
                expect(cycle_desc).to_contain("Circular dependency")
            end)

            it("should detect self-loop", function()
                local graph = template_graph.new()

                local node_a = uuid.v7()

                graph.nodes[node_a] = { node_id = node_a }
                graph.edges[node_a] = { node_a }

                local has_cycle, cycle_desc = graph:has_cycles()
                expect(has_cycle).to_be_true()
                expect(cycle_desc).to_contain("Circular dependency")
            end)

            it("should detect complex cycle in larger graph", function()
                local graph = template_graph.new()

                local node_a = uuid.v7()
                local node_b = uuid.v7()
                local node_c = uuid.v7()
                local node_d = uuid.v7()

                graph.nodes[node_a] = { node_id = node_a }
                graph.nodes[node_b] = { node_id = node_b }
                graph.nodes[node_c] = { node_id = node_c }
                graph.nodes[node_d] = { node_id = node_d }
                graph.edges[node_a] = { node_b }
                graph.edges[node_b] = { node_c }
                graph.edges[node_c] = { node_d }
                graph.edges[node_d] = { node_b } -- Creates cycle B->C->D->B

                local has_cycle, cycle_desc = graph:has_cycles()
                expect(has_cycle).to_be_true()
                expect(cycle_desc).to_contain("Circular dependency")
            end)
        end)

        describe("Template Discovery with Mocking", function()
            it("should build graph from successful template discovery", function()
                local mock_node_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_parent_nodes = function(parent_id)
                                return {
                                    with_statuses = function(status)
                                        return {
                                            all = function()
                                                return {
                                                    {
                                                        node_id = "template1",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {
                                                            data_targets = {
                                                                {
                                                                    data_type = "node.input",
                                                                    node_id = "template2"
                                                                }
                                                            }
                                                        }
                                                    },
                                                    {
                                                        node_id = "template2",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {}
                                                    }
                                                }, nil
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { node_reader = mock_node_reader }
                local parent_node = { dataflow_id = "test-df", node_id = "parent" }

                local graph, err = template_graph.build_for_node(parent_node, deps)

                expect(err).to_be_nil()
                expect(graph).not_to_be_nil()
                expect(graph:is_empty()).to_be_false()
                expect(#graph:get_all_nodes()).to_equal(2)
                expect(#graph:get_roots()).to_equal(1)
                expect(graph:get_roots()[1]).to_equal("template1") -- template1 is root, routes to template2
                expect(graph:get_edges("template1")[1]).to_equal("template2")
            end)

            it("should handle empty template discovery", function()
                local mock_node_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_parent_nodes = function(parent_id)
                                return {
                                    with_statuses = function(status)
                                        return {
                                            all = function()
                                                return {}, nil
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { node_reader = mock_node_reader }
                local parent_node = { dataflow_id = "test-df", node_id = "parent" }

                local graph, err = template_graph.build_for_node(parent_node, deps)

                expect(err).to_be_nil()
                expect(graph).not_to_be_nil()
                expect(graph:is_empty()).to_be_true()
            end)

            it("should handle node_reader error", function()
                local mock_node_reader = {
                    with_dataflow = function(dataflow_id)
                        return nil, "Database connection failed"
                    end
                }

                local deps = { node_reader = mock_node_reader }
                local parent_node = { dataflow_id = "test-df", node_id = "parent" }

                local graph, err = template_graph.build_for_node(parent_node, deps)

                expect(graph).to_be_nil()
                expect(err).to_contain("Failed to create node reader")
            end)

            it("should handle query error", function()
                local mock_node_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_parent_nodes = function(parent_id)
                                return {
                                    with_statuses = function(status)
                                        return {
                                            all = function()
                                                return nil, "Query execution failed"
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { node_reader = mock_node_reader }
                local parent_node = { dataflow_id = "test-df", node_id = "parent" }

                local graph, err = template_graph.build_for_node(parent_node, deps)

                expect(graph).to_be_nil()
                expect(err).to_contain("Failed to query template nodes")
            end)

            it("should track both data_targets and error_targets as edges", function()
                local mock_node_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_parent_nodes = function(parent_id)
                                return {
                                    with_statuses = function(status)
                                        return {
                                            all = function()
                                                return {
                                                    {
                                                        node_id = "template1",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {
                                                            data_targets = {
                                                                {
                                                                    data_type = "node.input",
                                                                    node_id = "template2"
                                                                }
                                                            },
                                                            error_targets = {
                                                                {
                                                                    data_type = "node.input",
                                                                    node_id = "template3"
                                                                }
                                                            }
                                                        }
                                                    },
                                                    {
                                                        node_id = "template2",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {}
                                                    },
                                                    {
                                                        node_id = "template3",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {}
                                                    }
                                                }, nil
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { node_reader = mock_node_reader }
                local parent_node = { dataflow_id = "test-df", node_id = "parent" }

                local graph, err = template_graph.build_for_node(parent_node, deps)

                expect(err).to_be_nil()
                expect(graph).not_to_be_nil()
                expect(#graph:get_all_nodes()).to_equal(3)
                expect(#graph:get_roots()).to_equal(1) -- Only template1 is root
                expect(graph:get_roots()[1]).to_equal("template1")

                local edges = graph:get_edges("template1")
                expect(#edges).to_equal(2)
                expect(edges[1]).to_equal("template2")
                expect(edges[2]).to_equal("template3")
            end)

            it("should reject circular dependencies", function()
                local mock_node_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_parent_nodes = function(parent_id)
                                return {
                                    with_statuses = function(status)
                                        return {
                                            all = function()
                                                return {
                                                    {
                                                        node_id = "template1",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {
                                                            data_targets = {
                                                                {
                                                                    data_type = "node.input",
                                                                    node_id = "template2"
                                                                }
                                                            }
                                                        }
                                                    },
                                                    {
                                                        node_id = "template2",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {
                                                            data_targets = {
                                                                {
                                                                    data_type = "node.input",
                                                                    node_id = "template1"
                                                                }
                                                            }
                                                        }
                                                    }
                                                }, nil
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { node_reader = mock_node_reader }
                local parent_node = { dataflow_id = "test-df", node_id = "parent" }

                local graph, err = template_graph.build_for_node(parent_node, deps)

                expect(graph).to_be_nil()
                expect(err).to_contain("circular dependencies")
            end)

            it("should reject graph where all nodes form a cycle", function()
                local mock_node_reader = {
                    with_dataflow = function(dataflow_id)
                        return {
                            with_parent_nodes = function(parent_id)
                                return {
                                    with_statuses = function(status)
                                        return {
                                            all = function()
                                                return {
                                                    {
                                                        node_id = "template1",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {
                                                            data_targets = {
                                                                {
                                                                    data_type = "node.input",
                                                                    node_id = "template2"
                                                                }
                                                            }
                                                        }
                                                    },
                                                    {
                                                        node_id = "template2",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {
                                                            data_targets = {
                                                                {
                                                                    data_type = "node.input",
                                                                    node_id = "template3"
                                                                }
                                                            }
                                                        }
                                                    },
                                                    {
                                                        node_id = "template3",
                                                        type = "func_node",
                                                        status = "template",
                                                        config = {
                                                            data_targets = {
                                                                {
                                                                    data_type = "node.input",
                                                                    node_id = "template1"
                                                                }
                                                            }
                                                        }
                                                    }
                                                }, nil
                                            end
                                        }
                                    end
                                }
                            end
                        }, nil
                    end
                }

                local deps = { node_reader = mock_node_reader }
                local parent_node = { dataflow_id = "test-df", node_id = "parent" }

                local graph, err = template_graph.build_for_node(parent_node, deps)

                expect(graph).to_be_nil()
                expect(err).to_contain("circular dependencies")
            end)
        end)

        describe("Invalid Parent Node", function()
            it("should reject invalid parent node", function()
                local graph, err = template_graph.build_for_node(nil)
                expect(graph).to_be_nil()
                expect(err).to_contain("Invalid parent node")

                local graph2, err2 = template_graph.build_for_node({})
                expect(graph2).to_be_nil()
                expect(err2).to_contain("Invalid parent node")

                local graph3, err3 = template_graph.build_for_node({ dataflow_id = "test" })
                expect(graph3).to_be_nil()
                expect(err3).to_contain("Invalid parent node")
            end)
        end)
    end)
end

return test.run_cases(define_tests)