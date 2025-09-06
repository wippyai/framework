local test = require("test")
local scheduler = require("scheduler")
local consts = require("consts")

local function define_tests()
    describe("Dataflow Scheduler", function()
        describe("Empty State Handling", function()
            it("should complete empty workflow", function()
                local state = scheduler.create_empty_state()

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_true()
                expect(decision.payload.message).to_contain("Empty workflow")
            end)

            it("should return no work when only completed nodes exist", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "test_node"
                    }
                }
                state.has_workflow_output = true

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_true()
            end)
        end)

        describe("Root Node Execution", function()
            it("should execute root node with inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["root-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "root_processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["root-1"] = { config = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("root-1")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("root_ready")
                expect(#decision.payload.nodes[1].path).to_equal(0)
            end)

            it("should not execute root node without required inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["root-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "root_processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["root-1"] = { required = { "config", "data" }, optional = {} }
                    },
                    available = {
                        ["root-1"] = { config = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("deadlocked")
            end)

            it("should execute root node even when other nodes are running", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["root-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "root_processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["root-1"] = { config = true }
                    }
                }
                state.active_processes = {
                    ["other-node"] = true
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("root-1")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("root_ready")
            end)
        end)

        describe("Yield-Driven Execution", function()
            it("should satisfy completed yield", function()
                local state = scheduler.create_empty_state()
                state.active_yields = {
                    ["parent-1"] = {
                        yield_id = "yield-123",
                        reply_to = "dataflow.yield_reply.parent-1",
                        pending_children = {
                            ["child-1"] = consts.STATUS.COMPLETED_SUCCESS,
                            ["child-2"] = consts.STATUS.COMPLETED_SUCCESS
                        },
                        results = {
                            ["child-1"] = "result-data-1",
                            ["child-2"] = "result-data-2"
                        }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.SATISFY_YIELD)
                expect(decision.payload.parent_id).to_equal("parent-1")
                expect(decision.payload.yield_id).to_equal("yield-123")
                expect(decision.payload.reply_to).to_equal("dataflow.yield_reply.parent-1")
            end)

            it("should execute yield child with inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["child-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "child_processor",
                        parent_node_id = "parent-1"
                    }
                }
                state.active_yields = {
                    ["parent-1"] = {
                        yield_id = "yield-123",
                        reply_to = "dataflow.yield_reply.parent-1",
                        pending_children = {
                            ["child-1"] = consts.STATUS.PENDING,
                            ["child-2"] = consts.STATUS.COMPLETED_SUCCESS
                        },
                        child_path = { "ancestor-1", "parent-1" }
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["child-1"] = { required = { "input" }, optional = {} }
                    },
                    available = {
                        ["child-1"] = { input = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("child-1")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("yield_driven")
                expect(decision.payload.nodes[1].parent_id).to_equal("parent-1")
                expect(#decision.payload.nodes[1].path).to_equal(2)
            end)

            it("should not execute yield child without inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["child-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "child_processor",
                        parent_node_id = "parent-1"
                    }
                }
                state.active_yields = {
                    ["parent-1"] = {
                        yield_id = "yield-123",
                        pending_children = {
                            ["child-1"] = consts.STATUS.PENDING
                        }
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["child-1"] = { required = { "input" }, optional = {} }
                    },
                    available = {
                        ["child-1"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.NO_WORK)
            end)
        end)

        describe("Input-Ready Execution", function()
            it("should execute non-root node with satisfied inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = "some-parent"
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["node-1"] = { required = { "data", "config" }, optional = { "metadata" } }
                    },
                    available = {
                        ["node-1"] = { data = true, config = true, metadata = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("node-1")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("input_ready")
            end)

            it("should deadlock when node has partial required inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = "some-parent"
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["node-1"] = { required = { "data", "config" }, optional = {} }
                    },
                    available = {
                        ["node-1"] = { data = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("deadlocked")
            end)

            it("should skip yield children in input-ready search", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["yield-child"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = "parent-1"
                    },
                    ["normal-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = "other-parent"
                    }
                }
                state.active_yields = {
                    ["parent-1"] = {
                        pending_children = {
                            ["yield-child"] = consts.STATUS.PENDING
                        }
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["yield-child"] = { required = { "input" }, optional = {} },
                        ["normal-node"] = { required = { "input" }, optional = {} }
                    },
                    available = {
                        ["yield-child"] = { input = true },
                        ["normal-node"] = { input = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("yield-child")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("yield_driven")
            end)
        end)

        describe("Priority Ordering", function()
            it("should prioritize yield satisfaction over new execution", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["ready-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }
                state.active_yields = {
                    ["parent-1"] = {
                        yield_id = "yield-123",
                        reply_to = "reply-topic",
                        pending_children = {
                            ["child-1"] = consts.STATUS.COMPLETED_SUCCESS
                        },
                        results = { ["child-1"] = "result" }
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["ready-node"] = { required = { "input" }, optional = {} }
                    },
                    available = {
                        ["ready-node"] = { input = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.SATISFY_YIELD)
                expect(decision.payload.parent_id).to_equal("parent-1")
            end)

            it("should prioritize yield children over input-ready nodes", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["yield-child"] = {
                        status = consts.STATUS.PENDING,
                        type = "child_processor",
                        parent_node_id = "parent-1"
                    },
                    ["normal-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }
                state.active_yields = {
                    ["parent-1"] = {
                        pending_children = {
                            ["yield-child"] = consts.STATUS.PENDING
                        }
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["yield-child"] = { required = { "input" }, optional = {} },
                        ["normal-node"] = { required = { "input" }, optional = {} }
                    },
                    available = {
                        ["yield-child"] = { input = true },
                        ["normal-node"] = { input = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("yield-child")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("yield_driven")
            end)
        end)

        describe("Completion Detection", function()
            it("should complete workflow successfully with all nodes complete", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "processor"
                    },
                    ["node-2"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "processor"
                    }
                }
                state.has_workflow_output = true

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_true()
                expect(decision.payload.message).to_contain("successfully")
            end)

            it("should complete workflow with failure when nodes failed", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "processor"
                    },
                    ["node-2"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "processor"
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("without producing output")
            end)

            it("should detect deadlock with pending nodes but no inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["node-1"] = { required = { "missing-input" }, optional = {} }
                    },
                    available = {
                        ["node-1"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("deadlocked")
            end)

            it("should not complete while processes are active", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.RUNNING,
                        type = "processor"
                    }
                }
                state.active_processes = {
                    ["node-1"] = true
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.NO_WORK)
            end)

            it("should not complete while yields are active", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "processor"
                    }
                }
                state.active_yields = {
                    ["parent-1"] = {
                        pending_children = {
                            ["child-1"] = consts.STATUS.PENDING
                        }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.NO_WORK)
            end)
        end)

        describe("Input Requirements Behavior", function()
            it("should execute node with inputs but no requirements", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["no-reqs-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["no-reqs-node"] = {
                            config = true,
                            data = true
                        }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("no-reqs-node")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("root_ready")
            end)

            it("should immediately fail for nodes with no requirements and no inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["no-reqs-no-inputs"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["no-reqs-no-inputs"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("No input data provided")
            end)

            it("should execute yield child with inputs but no requirements", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["yield-child-no-reqs"] = {
                        status = consts.STATUS.PENDING,
                        type = "child_processor",
                        parent_node_id = "parent-1"
                    }
                }
                state.active_yields = {
                    ["parent-1"] = {
                        yield_id = "yield-123",
                        pending_children = {
                            ["yield-child-no-reqs"] = consts.STATUS.PENDING
                        }
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["yield-child-no-reqs"] = {
                            input_data = true
                        }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("yield-child-no-reqs")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("yield_driven")
            end)

            it("should execute root node with inputs but no requirements", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["root-no-reqs"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["root-no-reqs"] = {
                            some_data = true,
                            config = true
                        }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("root-no-reqs")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("root_ready")
            end)

            it("should still deadlock when required inputs are missing", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["missing-required"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["missing-required"] = {
                            required = { "essential-input" },
                            optional = {}
                        }
                    },
                    available = {
                        ["missing-required"] = {
                            optional_data = true
                        }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("deadlocked")
            end)
        end)

        describe("Flexible Input Handling", function()
            it("should execute node with input data but no requirements", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["no-reqs-with-data"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["no-reqs-with-data"] = {
                            config = true,
                            data = true
                        }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("no-reqs-with-data")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("root_ready")
            end)

            it("should execute multiple nodes without requirements when they have inputs", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["flexible-node-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    },
                    ["flexible-node-2"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    },
                    ["good-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["good-node"] = { required = { "input" }, optional = {} }
                    },
                    available = {
                        ["flexible-node-1"] = { data = true },
                        ["flexible-node-2"] = { config = true },
                        ["good-node"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(2)

                local executed_nodes = {}
                for _, node in ipairs(decision.payload.nodes) do
                    executed_nodes[node.node_id] = true
                    expect(node.trigger_reason).to_equal("root_ready")
                end

                expect(executed_nodes["flexible-node-1"]).to_be_true()
                expect(executed_nodes["flexible-node-2"]).to_be_true()
                expect(executed_nodes["good-node"]).to_be_nil()
            end)

            it("should immediately fail nodes without input data", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["no-inputs-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["no-inputs-node"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("No input data provided")
            end)

            it("should execute flexible nodes over deadlocked nodes", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["flexible-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    },
                    ["deadlocked"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["deadlocked"] = { required = { "missing-input" }, optional = {} }
                    },
                    available = {
                        ["flexible-node"] = { data = true },
                        ["deadlocked"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("flexible-node")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("root_ready")
            end)

            it("should immediately fail when node has no inputs and no requirements", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["no-input-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["no-input-node"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("No input data provided")
            end)
        end)

        describe("Edge Cases", function()
            it("should immediately fail when node has no input requirements", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }
                state.input_tracker = {
                    requirements = {},
                    available = {}
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("No input data provided")
            end)

            it("should handle empty yield children list", function()
                local state = scheduler.create_empty_state()
                state.active_yields = {
                    ["parent-1"] = {
                        yield_id = "yield-123",
                        reply_to = "reply-topic",
                        pending_children = {},
                        results = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.SATISFY_YIELD)
                expect(decision.payload.parent_id).to_equal("parent-1")
            end)

            it("should handle optional inputs correctly", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["node-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["node-1"] = {
                            required = { "essential" },
                            optional = { "nice-to-have", "metadata" }
                        }
                    },
                    available = {
                        ["node-1"] = {
                            essential = true,
                            metadata = true
                        }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("node-1")
            end)
        end)

        describe("Complex Workflow Scenarios", function()
            it("should handle multi-level yield hierarchy", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["grandchild"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = "child"
                    }
                }
                state.active_yields = {
                    ["parent"] = {
                        pending_children = {
                            ["child"] = consts.STATUS.PENDING
                        }
                    },
                    ["child"] = {
                        pending_children = {
                            ["grandchild"] = consts.STATUS.PENDING
                        },
                        child_path = { "root", "parent", "child" }
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["grandchild"] = { required = { "input" }, optional = {} }
                    },
                    available = {
                        ["grandchild"] = { input = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("grandchild")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("yield_driven")
            end)

            it("should handle mixed root and yield scenarios", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["root-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "root_processor",
                        parent_node_id = nil
                    },
                    ["yield-child"] = {
                        status = consts.STATUS.PENDING,
                        type = "child_processor",
                        parent_node_id = "parent"
                    }
                }
                state.active_yields = {
                    ["parent"] = {
                        pending_children = {
                            ["yield-child"] = consts.STATUS.PENDING
                        }
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["root-node"] = { required = { "config" }, optional = {} },
                        ["yield-child"] = { required = { "data" }, optional = {} }
                    },
                    available = {
                        ["root-node"] = { config = true },
                        ["yield-child"] = { data = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("yield-child")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("yield_driven")
            end)
        end)

        describe("Concurrent Input-Ready Execution", function()
            it("should find multiple input-ready nodes concurrently when dependencies are satisfied", function()
                local state = scheduler.create_empty_state()

                state.nodes = {
                    ["node-a"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "processor",
                        parent_node_id = nil
                    },
                    ["node-b"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    },
                    ["node-c"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    },
                    ["node-d"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }

                state.input_tracker = {
                    requirements = {
                        ["node-b"] = { required = {"from_a"}, optional = {} },
                        ["node-c"] = { required = {"from_a"}, optional = {} },
                        ["node-d"] = { required = {"from_b", "from_c"}, optional = {} }
                    },
                    available = {
                        ["node-b"] = { from_a = true },
                        ["node-c"] = { from_a = true },
                        ["node-d"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(2)

                local executed_nodes = {}
                for _, node in ipairs(decision.payload.nodes) do
                    executed_nodes[node.node_id] = true
                    expect(node.trigger_reason).to_equal("input_ready")
                end

                expect(executed_nodes["node-b"]).to_be_true()
                expect(executed_nodes["node-c"]).to_be_true()
                expect(executed_nodes["node-d"]).to_be_nil()
            end)

            it("should NOT classify input-dependent nodes as root_ready", function()
                local state = scheduler.create_empty_state()

                state.nodes = {
                    ["dependency-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }

                state.input_tracker = {
                    requirements = {
                        ["dependency-node"] = { required = {"upstream_data"}, optional = {} }
                    },
                    available = {
                        ["dependency-node"] = { upstream_data = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("dependency-node")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("input_ready")
            end)

            it("should classify true root nodes as root_ready", function()
                local state = scheduler.create_empty_state()

                state.nodes = {
                    ["true-root"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor",
                        parent_node_id = nil
                    }
                }

                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["true-root"] = { config = true, workflow_input = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("true-root")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("root_ready")
            end)
        end)

        describe("Parent-Child Error Handling", function()
            it("should succeed when parent handles child failures successfully", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["map-reduce-parent"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "map_reduce_processor",
                        parent_node_id = nil
                    },
                    ["child-1"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "child_processor",
                        parent_node_id = "map-reduce-parent"
                    },
                    ["child-2"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "child_processor",
                        parent_node_id = "map-reduce-parent"
                    },
                    ["child-3"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "child_processor",
                        parent_node_id = "map-reduce-parent"
                    }
                }
                state.has_workflow_output = true

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_true()
                expect(decision.payload.message).to_contain("successfully")
            end)

            it("should fail when parent fails even if some children succeeded", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["map-reduce-parent"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "map_reduce_processor",
                        parent_node_id = nil
                    },
                    ["child-1"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "child_processor",
                        parent_node_id = "map-reduce-parent"
                    },
                    ["child-2"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "child_processor",
                        parent_node_id = "map-reduce-parent"
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("without producing output")
            end)

            it("should fail when orphaned nodes fail", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["root-node"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "processor",
                        parent_node_id = nil
                    },
                    ["orphan-failed"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "processor",
                        parent_node_id = nil
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("without producing output")
            end)

            it("should succeed with nested parent-child success despite grandchild failures", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["root-parent"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "root_processor",
                        parent_node_id = nil
                    },
                    ["middle-parent"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "middle_processor",
                        parent_node_id = "root-parent"
                    },
                    ["grandchild-1"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "child_processor",
                        parent_node_id = "middle-parent"
                    },
                    ["grandchild-2"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "child_processor",
                        parent_node_id = "middle-parent"
                    }
                }
                state.has_workflow_output = true

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_true()
                expect(decision.payload.message).to_contain("successfully")
            end)

            it("should fail when intermediate parent fails even if root succeeds", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["root-parent"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "root_processor",
                        parent_node_id = nil
                    },
                    ["middle-parent"] = {
                        status = consts.STATUS.COMPLETED_FAILURE,
                        type = "middle_processor",
                        parent_node_id = "root-parent"
                    },
                    ["grandchild"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "child_processor",
                        parent_node_id = "middle-parent"
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_false()
                expect(decision.payload.message).to_contain("without producing output")
            end)
        end)

        describe("Selective Node Loading Optimization", function()
            it("should handle scheduler snapshot with only active nodes", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["pending-node-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    },
                    ["running-node-1"] = {
                        status = consts.STATUS.RUNNING,
                        type = "processor"
                    },
                    ["pending-node-2"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }
                state.input_tracker = {
                    requirements = {
                        ["pending-node-1"] = { required = { "input" }, optional = {} },
                        ["pending-node-2"] = { required = { "input" }, optional = {} }
                    },
                    available = {
                        ["pending-node-1"] = { input = true },
                        ["pending-node-2"] = {}
                    }
                }
                state.active_processes = {
                    ["running-node-1"] = true
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("pending-node-1")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("input_ready")
            end)

            it("should efficiently complete workflow when has_workflow_output is true", function()
                local state = scheduler.create_empty_state()
                state.nodes = {
                    ["completed-node"] = {
                        status = consts.STATUS.COMPLETED_SUCCESS,
                        type = "processor"
                    }
                }
                state.active_processes = {}
                state.active_yields = {}
                state.has_workflow_output = true

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.COMPLETE_WORKFLOW)
                expect(decision.payload.success).to_be_true()
                expect(decision.payload.message).to_contain("successfully")
            end)

            it("should handle large workflow simulation with concurrent execution", function()
                local state = scheduler.create_empty_state()

                state.nodes = {
                    ["active-1"] = { status = consts.STATUS.PENDING, type = "processor" },
                    ["active-2"] = { status = consts.STATUS.PENDING, type = "processor" },
                    ["active-3"] = { status = consts.STATUS.RUNNING, type = "processor" },
                    ["active-4"] = { status = consts.STATUS.PENDING, type = "processor" }
                }

                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["active-1"] = { config = true },
                        ["active-2"] = { config = true },
                        ["active-4"] = { config = true }
                    }
                }

                state.active_processes = {
                    ["active-3"] = true
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(3)

                local executed_nodes = {}
                for _, node in ipairs(decision.payload.nodes) do
                    executed_nodes[node.node_id] = true
                    expect(node.trigger_reason).to_equal("root_ready")
                end

                expect(executed_nodes["active-1"]).to_be_true()
                expect(executed_nodes["active-2"]).to_be_true()
                expect(executed_nodes["active-4"]).to_be_true()
                expect(executed_nodes["active-3"]).to_be_nil()
            end)
        end)

        describe("Concurrent Execution", function()
            it("should return multiple nodes for concurrent execution in diamond pattern", function()
                local state = scheduler.create_empty_state()

                state.nodes = {
                    ["node-b"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    },
                    ["node-c"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    },
                    ["node-d"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }

                state.input_tracker = {
                    requirements = {
                        ["node-b"] = { required = { "from_a" }, optional = {} },
                        ["node-c"] = { required = { "from_a" }, optional = {} },
                        ["node-d"] = { required = { "from_b", "from_c" }, optional = {} }
                    },
                    available = {
                        ["node-b"] = { from_a = true },
                        ["node-c"] = { from_a = true },
                        ["node-d"] = {}
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(2)

                local node_ids = {}
                for _, node_info in ipairs(decision.payload.nodes) do
                    table.insert(node_ids, node_info.node_id)
                    expect(node_info.trigger_reason).to_equal("input_ready")
                end

                expect(node_ids[1] == "node-b" or node_ids[1] == "node-c").to_be_true()
                expect(node_ids[2] == "node-b" or node_ids[2] == "node-c").to_be_true()
                expect(node_ids[1]).not_to_equal(node_ids[2])
            end)

            it("should batch independent root nodes for concurrent execution", function()
                local state = scheduler.create_empty_state()

                state.nodes = {
                    ["root-1"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    },
                    ["root-2"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    },
                    ["root-3"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }

                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["root-1"] = { config = true },
                        ["root-2"] = { config = true },
                        ["root-3"] = { config = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(3)

                local scheduled_ids = {}
                for _, node_info in ipairs(decision.payload.nodes) do
                    table.insert(scheduled_ids, node_info.node_id)
                    expect(node_info.trigger_reason).to_equal("root_ready")
                end

                local has_root1 = false
                local has_root2 = false
                local has_root3 = false
                for _, id in ipairs(scheduled_ids) do
                    if id == "root-1" then has_root1 = true end
                    if id == "root-2" then has_root2 = true end
                    if id == "root-3" then has_root3 = true end
                end

                expect(has_root1).to_be_true()
                expect(has_root2).to_be_true()
                expect(has_root3).to_be_true()
            end)

            it("should handle single execution when only one node is ready", function()
                local state = scheduler.create_empty_state()

                state.nodes = {
                    ["single-node"] = {
                        status = consts.STATUS.PENDING,
                        type = "processor"
                    }
                }

                state.input_tracker = {
                    requirements = {},
                    available = {
                        ["single-node"] = { config = true }
                    }
                }

                local decision = scheduler.find_next_work(state)

                expect(decision.type).to_equal(scheduler.DECISION_TYPE.EXECUTE_NODES)
                expect(#decision.payload.nodes).to_equal(1)
                expect(decision.payload.nodes[1].node_id).to_equal("single-node")
                expect(decision.payload.nodes[1].trigger_reason).to_equal("root_ready")
            end)
        end)
    end)
end

return test.run_cases(define_tests)