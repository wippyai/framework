local test = require("test")
local uuid = require("uuid")
local json = require("json")
local client = require("client")
local consts = require("consts")
local data_reader = require("data_reader")
local map_reduce = require("map_reduce")

local function define_tests()
    describe("Map-Reduce Tests", function()
        describe("Unit Tests - Configuration Validation", function()
            it("should validate failure strategies", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            failure_strategy = "invalid_strategy"
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.INVALID_FAILURE_STRATEGY)
            end)

            it("should validate batch size", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            batch_size = -1
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.INVALID_BATCH_SIZE)
            end)

            it("should require source_array_key", function()
                local mock_node = {
                    config = function(self)
                        return {}
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.MISSING_SOURCE_ARRAY_KEY)
            end)

            it("should require input data", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items"
                        }
                    end,
                    inputs = function(self)
                        return {}
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.NO_INPUT_DATA)
            end)

            it("should validate input structure", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items"
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { wrong_key = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.INVALID_INPUT_STRUCTURE)
            end)

            it("should require non-empty array", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items"
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = {} }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.INVALID_INPUT_STRUCTURE)
            end)

            it("should validate item_steps configuration", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            item_steps = "invalid_pipeline" -- Should be table
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.INVALID_PIPELINE_STEP)
            end)

            it("should validate item step structure", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            item_steps = {
                                { type = "invalid_type", func_id = "test_func" }
                            }
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.INVALID_PIPELINE_STEP)
            end)

            it("should validate extractor names", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            reduction_extract = "invalid_extractor"
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.INVALID_EXTRACTOR)
            end)

            it("should validate reduction pipeline compatibility", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            reduction_extract = "invalid_extractor" -- Invalid extractor
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.INVALID_EXTRACTOR)
            end)
        end)

        describe("Unit Tests - Extractors", function()
            it("should extract successes correctly", function()
                local map_reduce_result = {
                    successes = {
                        { iteration = 1, item = "a", result = "result_a" },
                        { iteration = 2, item = "b", result = "result_b" }
                    },
                    failures = {
                        { iteration = 3, item = "c", error = "failed" }
                    },
                    success_count = 2,
                    failure_count = 1,
                    total_iterations = 3
                }

                local extractor = map_reduce.extractors[map_reduce.EXTRACTORS.SUCCESSES]
                local result = extractor(map_reduce_result)

                expect(#result).to_equal(2)
                expect(result[1]).to_equal("result_a")
                expect(result[2]).to_equal("result_b")
            end)

            it("should extract failures correctly", function()
                local map_reduce_result = {
                    successes = {
                        { iteration = 1, item = "a", result = "result_a" }
                    },
                    failures = {
                        { iteration = 2, item = "b", error = "error_b" },
                        { iteration = 3, item = "c", error = "error_c" }
                    },
                    success_count = 1,
                    failure_count = 2,
                    total_iterations = 3
                }

                local extractor = map_reduce.extractors[map_reduce.EXTRACTORS.FAILURES]
                local result = extractor(map_reduce_result)

                expect(#result).to_equal(2)
                expect(result[1].item).to_equal("b")
                expect(result[1].error).to_equal("error_b")
                expect(result[2].item).to_equal("c")
                expect(result[2].error).to_equal("error_c")
            end)
        end)

        describe("Unit Tests - Template Discovery", function()
            it("should require template nodes", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items"
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return true
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.NO_TEMPLATES)
            end)

            it("should handle template discovery errors", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items"
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return nil, "Template discovery failed"
                    end
                }

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.TEMPLATE_DISCOVERY_FAILED)
            end)
        end)

        describe("Unit Tests - Batch Processing", function()
            it("should process successful batch", function()
                local batches_processed = 0
                local yield_called = false

                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            batch_size = 2
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b", "c" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        yield_called = true
                        return {}, nil
                    end,
                    complete = function(self, result, message)
                        return {
                            success = true,
                            result = result,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        batches_processed = batches_processed + 1
                        return {
                            {
                                iteration_index = batch_start,
                                input_item = items[batch_start],
                                root_nodes = { "node1" }
                            }
                        }, nil
                    end,
                    collect_results = function(n, iteration)
                        return "result_" .. iteration.iteration_index, nil
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator

                local result = map_reduce.run({})
                expect(result.success).to_be_true()
                expect(batches_processed).to_equal(2) -- 3 items in batches of 2
                expect(yield_called).to_be_true()
            end)

            it("should handle fail_fast strategy", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            failure_strategy = map_reduce.FAILURE_STRATEGIES.FAIL_FAST
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        return {}, nil
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        return nil, "Iteration creation failed"
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.ITERATION_FAILED)
            end)
        end)

        describe("Unit Tests - Item Pipeline Functionality", function()
            it("should apply item pipeline when configured", function()
                local item_pipeline_called = false
                local item_pipeline_input = nil

                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            item_steps = {
                                { type = "map", func_id = "transform_item" }
                            }
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        return {}, nil
                    end,
                    complete = function(self, result, message)
                        return {
                            success = true,
                            result = result,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        return {
                            {
                                iteration_index = 1,
                                input_item = "a",
                                root_nodes = { "node1" }
                            }
                        }, nil
                    end,
                    collect_results = function(n, iteration)
                        return "large_result", nil
                    end
                }

                local mock_funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                item_pipeline_called = true
                                item_pipeline_input = data
                                return "processed_" .. tostring(data), nil
                            end
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator
                map_reduce._deps.funcs = mock_funcs

                local result = map_reduce.run({})
                expect(result.success).to_be_true()
                expect(item_pipeline_called).to_be_true()
                expect(item_pipeline_input).to_equal("large_result")
                expect(result.result.successes[1].result).to_equal("processed_large_result")
            end)

            it("should handle item pipeline errors with fail_fast strategy", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            failure_strategy = map_reduce.FAILURE_STRATEGIES.FAIL_FAST,
                            item_steps = {
                                { type = "map", func_id = "failing_transform" }
                            }
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        return {}, nil
                    end,
                    complete = function(self, result, message)
                        return {
                            success = true,
                            result = result,
                            message = message
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        return {
                            {
                                iteration_index = 1,
                                input_item = "a",
                                root_nodes = { "node1" }
                            }
                        }, nil
                    end,
                    collect_results = function(n, iteration)
                        return "large_result", nil
                    end
                }

                local mock_funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                return nil, "Item transform failed"
                            end
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator
                map_reduce._deps.funcs = mock_funcs

                local result = map_reduce.run({})
                expect(result.success).to_be_false()
                expect(result.error.code).to_equal(map_reduce.ERRORS.ITERATION_FAILED)
                expect(result.error.message).to_contain("Item pipeline failed")
            end)

            it("should handle item pipeline errors with collect_errors strategy", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            failure_strategy = map_reduce.FAILURE_STRATEGIES.COLLECT_ERRORS,
                            item_steps = {
                                { type = "map", func_id = "failing_transform" }
                            }
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        return {}, nil
                    end,
                    complete = function(self, result, message)
                        return {
                            success = true,
                            result = result,
                            message = message
                        }
                    end,
                    fail = function(self, error_details, message)
                        return {
                            success = false,
                            error = error_details,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        return {
                            {
                                iteration_index = 1,
                                input_item = "a",
                                root_nodes = { "node1" }
                            }
                        }, nil
                    end,
                    collect_results = function(n, iteration)
                        return "large_result", nil
                    end
                }

                local mock_funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                return nil, "Item transform failed"
                            end
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator
                map_reduce._deps.funcs = mock_funcs

                local result = map_reduce.run({})
                expect(result.success).to_be_true()
                expect(result.result.failures).not_to_be_nil()
                expect(result.result.failure_count).to_equal(1)
                expect(result.result.failures[1].error).to_contain("Item pipeline failed")
            end)

            it("should support multi-step item pipelines", function()
                local step_calls = {}

                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            item_steps = {
                                { type = "map",    func_id = "step1" },
                                { type = "filter", func_id = "step2" },
                                { type = "map",    func_id = "step3" }
                            }
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        return {}, nil
                    end,
                    complete = function(self, result, message)
                        return {
                            success = true,
                            result = result,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        return {
                            {
                                iteration_index = 1,
                                input_item = "a",
                                root_nodes = { "node1" }
                            }
                        }, nil
                    end,
                    collect_results = function(n, iteration)
                        return "original", nil
                    end
                }

                local mock_funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                table.insert(step_calls, func_id)
                                if func_id == "step1" then
                                    return "transformed", nil
                                elseif func_id == "step2" then
                                    return true, nil -- Filter keeps the item
                                elseif func_id == "step3" then
                                    return "final", nil
                                end
                            end
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator
                map_reduce._deps.funcs = mock_funcs

                local result = map_reduce.run({})
                expect(result.success).to_be_true()
                expect(#step_calls).to_equal(3)
                expect(step_calls[1]).to_equal("step1")
                expect(step_calls[2]).to_equal("step2")
                expect(step_calls[3]).to_equal("step3")
                expect(result.result.successes[1].result).to_equal("final")
            end)

            it("should handle item filtering correctly", function()
                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            item_steps = {
                                { type = "filter", func_id = "filter_out_item" }
                            }
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        return {}, nil
                    end,
                    complete = function(self, result, message)
                        return {
                            success = true,
                            result = result,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        return {
                            {
                                iteration_index = batch_start,
                                input_item = items[batch_start],
                                root_nodes = { "node1" }
                            }
                        }, nil
                    end,
                    collect_results = function(n, iteration)
                        return "result_" .. iteration.iteration_index, nil
                    end
                }

                local mock_funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                -- Filter out first item, keep second
                                return data ~= "result_1", nil
                            end
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator
                map_reduce._deps.funcs = mock_funcs

                local result = map_reduce.run({})
                expect(result.success).to_be_true()
                expect(result.result.success_count).to_equal(1)                -- Only one item passed filter
                expect(result.result.successes[1].result).to_equal("result_2") -- Second item
            end)
        end)

        describe("Unit Tests - Reduction Functionality", function()
            it("should apply reducer when configured", function()
                local reducer_called = false
                local reducer_input = nil

                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            reduction_extract = "successes",
                            reduction_steps = {
                                { type = "aggregate", func_id = "test_reducer" }
                            }
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        return {}, nil
                    end,
                    complete = function(self, result, message)
                        return {
                            success = true,
                            result = result,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        return {
                            {
                                iteration_index = 1,
                                input_item = "a",
                                root_nodes = { "node1" }
                            }
                        }, nil
                    end,
                    collect_results = function(n, iteration)
                        return "result_a", nil
                    end
                }

                local mock_funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                reducer_called = true
                                reducer_input = data
                                return "reduced_result", nil
                            end
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator
                map_reduce._deps.funcs = mock_funcs

                local result = map_reduce.run({})
                expect(result.success).to_be_true()
                expect(reducer_called).to_be_true()
                expect(reducer_input).not_to_be_nil()
                expect(result.result).to_equal("reduced_result")
            end)

            it("should extract successes and process with pipeline", function()
                local pipeline_calls = {}

                local mock_node = {
                    config = function(self)
                        return {
                            source_array_key = "items",
                            reduction_extract = "successes",
                            reduction_steps = {
                                { type = "map",       func_id = "extract_score" },
                                { type = "aggregate", func_id = "sum_scores" }
                            }
                        }
                    end,
                    inputs = function(self)
                        return {
                            default = {
                                content = { items = { "a", "b" } }
                            }
                        }
                    end,
                    yield = function(self, options)
                        return {}, nil
                    end,
                    complete = function(self, result, message)
                        return {
                            success = true,
                            result = result,
                            message = message
                        }
                    end
                }

                local mock_template_graph = {
                    is_empty = function(self)
                        return false
                    end
                }

                local mock_iterator = {
                    create_batch = function(n, template_graph, items, batch_start, batch_end, iteration_input_key)
                        return {
                            {
                                iteration_index = batch_start,
                                input_item = items[batch_start],
                                root_nodes = { "node1" }
                            }
                        }, nil
                    end,
                    collect_results = function(n, iteration)
                        return { user_id = iteration.iteration_index, score = iteration.iteration_index * 10 }, nil
                    end
                }

                local mock_funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                table.insert(pipeline_calls, { func_id = func_id, data_type = type(data) })

                                if func_id == "extract_score" then
                                    return data.score, nil -- Extract score from user result
                                elseif func_id == "sum_scores" then
                                    local total = 0
                                    for _, score in ipairs(data) do
                                        total = total + score
                                    end
                                    return { total_score = total, count = #data }, nil
                                end
                            end
                        }
                    end
                }

                map_reduce._deps.node = {
                    new = function(args)
                        return mock_node, nil
                    end
                }

                map_reduce._deps.template_graph = {
                    build_for_node = function(node)
                        return mock_template_graph, nil
                    end
                }

                map_reduce._deps.iterator = mock_iterator
                map_reduce._deps.funcs = mock_funcs

                local result = map_reduce.run({})
                expect(result.success).to_be_true()
                expect(#pipeline_calls).to_equal(3) -- 2 map calls + 1 aggregate call
                expect(pipeline_calls[1].func_id).to_equal("extract_score")
                expect(pipeline_calls[2].func_id).to_equal("extract_score")
                expect(pipeline_calls[3].func_id).to_equal("sum_scores")
                expect(result.result.total_score).to_equal(30) -- 10 + 20
                expect(result.result.count).to_equal(2)
            end)
        end)

        describe("Unit Tests - Pipeline Functions", function()
            it("should validate item pipeline steps correctly", function()
                -- Test valid item pipeline steps
                local valid_steps = {
                    { type = "map",    func_id = "test_func" },
                    { type = "filter", func_id = "test_func" }
                }

                for _, step in ipairs(valid_steps) do
                    local valid, err = map_reduce.validate_item_pipeline_step(step)
                    expect(valid).to_be_true()
                    expect(err).to_be_nil()
                end

                -- Test invalid item pipeline steps
                local invalid_steps = {
                    nil,
                    {},
                    { func_id = "test" },                        -- Missing type
                    { type = "invalid_type", func_id = "test" },
                    { type = "map" },                            -- Missing func_id
                    { type = "group",        func_id = "test" }, -- Group not allowed in item pipeline
                }

                for _, step in ipairs(invalid_steps) do
                    local valid, err = map_reduce.validate_item_pipeline_step(step)
                    expect(valid).to_be_false()
                    expect(err).not_to_be_nil()
                end
            end)

            it("should validate reduction pipeline flow correctly", function()
                -- Valid: successes extractor with map step
                local valid, err = map_reduce.validate_reduction_pipeline_flow("successes", {
                    { type = "map", func_id = "test" }
                })
                expect(valid).to_be_true()
                expect(err).to_be_nil()

                -- Valid: failures extractor with filter step
                valid, err = map_reduce.validate_reduction_pipeline_flow("failures", {
                    { type = "filter", func_id = "test" }
                })
                expect(valid).to_be_true()
                expect(err).to_be_nil()

                -- Valid: any extractor with aggregate step
                valid, err = map_reduce.validate_reduction_pipeline_flow("successes", {
                    { type = "aggregate", func_id = "test" }
                })
                expect(valid).to_be_true()
                expect(err).to_be_nil()
            end)

            it("should execute item pipeline map step correctly", function()
                local call_data = nil
                map_reduce._deps.funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                call_data = data
                                return "transformed_" .. data, nil
                            end
                        }
                    end
                }

                local step = { type = "map", func_id = "transform" }
                local data = "single_value"

                local result, err = map_reduce.execute_item_pipeline_step(step, data)
                expect(err).to_be_nil()
                expect(result).to_equal("transformed_single_value")
                expect(call_data).to_equal("single_value")
            end)

            it("should execute reduction pipeline map step correctly", function()
                local calls = {}
                local call_count = 0

                -- Mock the funcs module to track calls across all executor instances
                map_reduce._deps.funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                call_count = call_count + 1
                                table.insert(calls, data)
                                return "transformed_" .. data, nil
                            end
                        }
                    end
                }

                local step = { type = "map", func_id = "transform" }
                local data = { "a", "b", "c" }

                local result, err = map_reduce.execute_reduction_pipeline_step(step, data)
                expect(err).to_be_nil()
                expect(#result).to_equal(3)
                expect(result[1]).to_equal("transformed_a")
                expect(result[2]).to_equal("transformed_b")
                expect(result[3]).to_equal("transformed_c")
                expect(call_count).to_equal(3)
            end)

            it("should execute reduction pipeline group step correctly", function()
                map_reduce._deps.funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            call = function(self, func_id, item)
                                return item.category, nil
                            end
                        }
                    end
                }

                local step = { type = "group", key_func_id = "get_category" }
                local data = {
                    { category = "A", value = 1 },
                    { category = "B", value = 2 },
                    { category = "A", value = 3 }
                }

                local result, err = map_reduce.execute_reduction_pipeline_step(step, data)
                expect(err).to_be_nil()
                expect(result["A"]).not_to_be_nil()
                expect(result["B"]).not_to_be_nil()
                expect(#result["A"]).to_equal(2)
                expect(#result["B"]).to_equal(1)
            end)
        end)

        describe("Unit Tests - Per-Step Context Functionality", function()
            it("should validate per-step context in item steps", function()
                local step_with_invalid_context = {
                    type = "map",
                    func_id = "test_func",
                    context = "invalid_context" -- Should be table
                }

                local valid, err = map_reduce.validate_item_pipeline_step(step_with_invalid_context)
                expect(valid).to_be_false()
                expect(err).to_contain("context must be a table")
            end)

            it("should validate per-step context in reduction steps", function()
                local step_with_invalid_context = {
                    type = "map",
                    func_id = "test_func",
                    context = 123 -- Should be table
                }

                local valid, err = map_reduce.validate_reduction_pipeline_step(step_with_invalid_context, "array")
                expect(valid).to_be_false()
                expect(err).to_contain("context must be a table")
            end)

            it("should execute item step with per-step context", function()
                local context_received = nil
                local data_received = nil

                map_reduce._deps.funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                context_received = context
                                return self
                            end,
                            call = function(self, func_id, data)
                                data_received = data
                                return "transformed_" .. data, nil
                            end
                        }
                    end
                }

                local step = {
                    type = "map",
                    func_id = "transform_data",
                    context = {
                        transform_mode = "aggressive",
                        preserve_type = true
                    }
                }

                local result, err = map_reduce.execute_item_pipeline_step(step, "test_data")

                expect(err).to_be_nil()
                expect(result).to_equal("transformed_test_data")
                expect(context_received).not_to_be_nil()
                expect(context_received.transform_mode).to_equal("aggressive")
                expect(context_received.preserve_type).to_be_true()
                expect(data_received).to_equal("test_data")
            end)

            it("should execute reduction step with per-step context", function()
                local context_received = nil

                map_reduce._deps.funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                context_received = context
                                return self
                            end,
                            call = function(self, func_id, data)
                                return { aggregated = data }, nil
                            end
                        }
                    end
                }

                local step = {
                    type = "aggregate",
                    func_id = "aggregate_data",
                    context = {
                        aggregation_method = "sum",
                        include_metadata = true
                    }
                }

                local result, err = map_reduce.execute_reduction_pipeline_step(step, { "value1", "value2" })

                expect(err).to_be_nil()
                expect(result.aggregated).not_to_be_nil()
                expect(context_received).not_to_be_nil()
                expect(context_received.aggregation_method).to_equal("sum")
                expect(context_received.include_metadata).to_be_true()
            end)

            it("should work without per-step context", function()
                local context_received = nil

                map_reduce._deps.funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                context_received = context
                                return self
                            end,
                            call = function(self, func_id, data)
                                return "processed_" .. data, nil
                            end
                        }
                    end
                }

                local step = {
                    type = "map",
                    func_id = "process_data"
                    -- No context
                }

                local result, err = map_reduce.execute_item_pipeline_step(step, "test_data")

                expect(err).to_be_nil()
                expect(result).to_equal("processed_test_data")
                expect(context_received).to_be_nil() -- No context should be set
            end)

            it("should merge context correctly in reduction map steps", function()
                local contexts_received = {}

                map_reduce._deps.funcs = {
                    new = function()
                        return {
                            with_context = function(self, context)
                                table.insert(contexts_received, context)
                                return self
                            end,
                            call = function(self, func_id, data)
                                return "processed_" .. data, nil
                            end
                        }
                    end
                }

                local step = {
                    type = "map",
                    func_id = "process",
                    context = {
                        global_setting = "test",
                        step_setting = "map_specific"
                    }
                }
                local data = { "item1", "item2" }

                local result, err = map_reduce.execute_reduction_pipeline_step(step, data)
                expect(err).to_be_nil()
                expect(#contexts_received).to_equal(2)

                -- Each context should have the step context plus item-specific data
                for i, context in ipairs(contexts_received) do
                    expect(context.global_setting).to_equal("test")
                    expect(context.step_setting).to_equal("map_specific")
                    expect(context.current_item).to_equal(data[i])
                    expect(context.item_index).to_equal(i)
                end
            end)
        end)
    end)

    describe("Integration Tests", function()
            describe("Basic Map-Reduce Workflow", function()
                it("should execute simple map-reduce with multiple items", function()
                    print("=== BASIC MAP-REDUCE INTEGRATION TEST START ===")

                    local c, err = client.new()
                    expect(err).to_be_nil()
                    expect(c).not_to_be_nil()

                    local map_reduce_node_id = uuid.v7()
                    local template_node_id = uuid.v7()
                    local input_data_id = uuid.v7()
                    local node_input_id = uuid.v7()

                    local test_input = {
                        items = {
                            { message = "Process item A", value = 10, delay_ms = 50 },
                            { message = "Process item B", value = 20, delay_ms = 50 },
                            { message = "Process item C", value = 30, delay_ms = 50 }
                        }
                    }

                    local workflow_commands = {
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = map_reduce_node_id,
                                node_type = "wippy.dataflow.node.map_reduce:map_reduce",
                                status = consts.STATUS.PENDING,
                                config = {
                                    source_array_key = "items",
                                    iteration_input_key = "default",
                                    batch_size = 1,
                                    failure_strategy = "collect_errors",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                            key = "map_reduce_result",
                                            content_type = consts.CONTENT_TYPE.JSON
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Basic Map-Reduce Node"
                                }
                            }
                        },
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = template_node_id,
                                node_type = "wippy.dataflow.node.func:node",
                                parent_node_id = map_reduce_node_id,
                                status = consts.STATUS.TEMPLATE,
                                config = {
                                    func_id = "wippy.dataflow.node.func:test_func",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.NODE_OUTPUT,
                                            key = "processed_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Basic Map-Reduce Template Node"
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
                                node_id = map_reduce_node_id,
                                key = input_data_id,
                                content = "",
                                content_type = "dataflow/reference"
                            }
                        }
                    }

                    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                        metadata = {
                            title = "Basic Map-Reduce Integration Test Workflow"
                        }
                    })
                    expect(create_err).to_be_nil()
                    expect(dataflow_id).not_to_be_nil()
                    print("✓ Basic map-reduce workflow created:", dataflow_id)

                    local result, exec_err = c:execute(dataflow_id)
                    expect(exec_err).to_be_nil()
                    expect(result).not_to_be_nil()
                    expect(result.success).to_be_true()
                    print("✓ Basic map-reduce workflow executed successfully")

                    local output_data = data_reader.with_dataflow(dataflow_id)
                        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                        :with_data_keys("map_reduce_result")
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

                    expect(output_content.successes).not_to_be_nil()
                    expect(output_content.failures).not_to_be_nil()
                    expect(#output_content.successes).to_equal(3)
                    expect(#output_content.failures).to_equal(0)
                    expect(output_content.success_count).to_equal(3)
                    expect(output_content.failure_count).to_equal(0)
                    expect(output_content.total_iterations).to_equal(3)

                    for i, success in ipairs(output_content.successes) do
                        expect(success.iteration).to_equal(i)
                        expect(success.item).not_to_be_nil()
                        expect(success.item.message).to_contain("Process item")
                        expect(success.result).not_to_be_nil()

                        local parsed_result = success.result
                        if type(success.result) == "string" then
                            local decoded, decode_err = json.decode(success.result)
                            if not decode_err then
                                parsed_result = decoded
                            end
                        end

                        expect(parsed_result.processed_by).to_equal("test_function")
                        expect(parsed_result.success).to_be_true()
                        print("  ✓ Iteration", i, "processed:", success.item.message)
                    end

                    print("=== BASIC MAP-REDUCE INTEGRATION TEST COMPLETE ===")
                end)

                it("should handle batch processing correctly", function()
                    print("=== BATCH PROCESSING TEST START ===")

                    local c, err = client.new()
                    expect(err).to_be_nil()

                    local map_reduce_node_id = uuid.v7()
                    local template_node_id = uuid.v7()
                    local input_data_id = uuid.v7()
                    local node_input_id = uuid.v7()

                    local test_input = {
                        items = {
                            { message = "Batch item 1", value = 1 },
                            { message = "Batch item 2", value = 2 },
                            { message = "Batch item 3", value = 3 },
                            { message = "Batch item 4", value = 4 },
                            { message = "Batch item 5", value = 5 }
                        }
                    }

                    local workflow_commands = {
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = map_reduce_node_id,
                                node_type = "wippy.dataflow.node.map_reduce:map_reduce",
                                status = consts.STATUS.PENDING,
                                config = {
                                    source_array_key = "items",
                                    batch_size = 2,
                                    failure_strategy = "collect_errors",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                            key = "batched_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Batch Processing Map-Reduce Node"
                                }
                            }
                        },
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = template_node_id,
                                node_type = "wippy.dataflow.node.func:node",
                                parent_node_id = map_reduce_node_id,
                                status = consts.STATUS.TEMPLATE,
                                config = {
                                    func_id = "wippy.dataflow.node.func:test_func",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.NODE_OUTPUT,
                                            key = "batch_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Batch Processing Template Node"
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
                                node_id = map_reduce_node_id,
                                key = input_data_id,
                                content = "",
                                content_type = "dataflow/reference"
                            }
                        }
                    }

                    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                        metadata = {
                            title = "Batch Processing Test Workflow"
                        }
                    })
                    expect(create_err).to_be_nil()

                    local result, exec_err = c:execute(dataflow_id)
                    expect(exec_err).to_be_nil()
                    expect(result.success).to_be_true()

                    local output_data = data_reader.with_dataflow(dataflow_id)
                        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                        :with_data_keys("batched_result")
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

                    expect(output_content.success_count).to_equal(5)
                    expect(output_content.total_iterations).to_equal(5)

                    print("✓ Batch processing completed with", output_content.success_count, "successes")
                    print("=== BATCH PROCESSING TEST COMPLETE ===")
                end)
            end)

            describe("Item Pipeline Integration", function()
                it("should apply item pipeline to compress iteration results", function()
                    print("=== ITEM PIPELINE COMPRESS TEST START ===")

                    local c, err = client.new()
                    expect(err).to_be_nil()

                    local map_reduce_node_id = uuid.v7()
                    local template_node_id = uuid.v7()
                    local input_data_id = uuid.v7()
                    local node_input_id = uuid.v7()

                    local test_input = {
                        items = {
                            { message = "Item 1", value = 100 },
                            { message = "Item 2", value = 200 }
                        }
                    }

                    local workflow_commands = {
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = map_reduce_node_id,
                                node_type = "wippy.dataflow.node.map_reduce:map_reduce",
                                status = consts.STATUS.PENDING,
                                config = {
                                    source_array_key = "items",
                                    failure_strategy = "collect_errors",
                                    item_steps = {
                                        {
                                            type = "map",
                                            func_id = "wippy.dataflow.node.map_reduce.stub:compress_item",
                                            context = {
                                                extract_only = true
                                            }
                                        }
                                    },
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                            key = "compressed_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Item Pipeline Compress Node"
                                }
                            }
                        },
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = template_node_id,
                                node_type = "wippy.dataflow.node.func:node",
                                parent_node_id = map_reduce_node_id,
                                status = consts.STATUS.TEMPLATE,
                                config = {
                                    func_id = "wippy.dataflow.node.func:test_func",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.NODE_OUTPUT,
                                            key = "result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Item Pipeline Compress Template Node"
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
                                node_id = map_reduce_node_id,
                                key = input_data_id,
                                content = "",
                                content_type = "dataflow/reference"
                            }
                        }
                    }

                    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                        metadata = {
                            title = "Item Pipeline Compress Test Workflow"
                        }
                    })
                    expect(create_err).to_be_nil()

                    local result, exec_err = c:execute(dataflow_id)
                    expect(exec_err).to_be_nil()
                    expect(result.success).to_be_true()

                    local output_data = data_reader.with_dataflow(dataflow_id)
                        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                        :with_data_keys("compressed_result")
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

                    expect(output_content.success_count).to_equal(2)

                    for _, success in ipairs(output_content.successes) do
                        expect(success.result.compressed_by).to_equal("compress_item")
                        expect(success.result.original_data).not_to_be_nil()
                        print("✓ Item compressed:", success.item.message)
                    end

                    print("=== ITEM PIPELINE COMPRESS TEST COMPLETE ===")
                end)

                it("should apply item pipeline validation filter", function()
                    print("=== ITEM PIPELINE VALIDATION TEST START ===")

                    local c, err = client.new()
                    expect(err).to_be_nil()

                    local map_reduce_node_id = uuid.v7()
                    local template_node_id = uuid.v7()
                    local input_data_id = uuid.v7()
                    local node_input_id = uuid.v7()

                    local test_input = {
                        items = {
                            { message = "Good item",         value = 50 },
                            { message = "Bad item",          value = 5 }, -- Will be filtered out
                            { message = "Another good item", value = 75 }
                        }
                    }

                    local workflow_commands = {
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = map_reduce_node_id,
                                node_type = "wippy.dataflow.node.map_reduce:map_reduce",
                                status = consts.STATUS.PENDING,
                                config = {
                                    source_array_key = "items",
                                    failure_strategy = "collect_errors",
                                    item_steps = {
                                        {
                                            type = "filter",
                                            func_id = "wippy.dataflow.node.map_reduce.stub:validate_item",
                                            context = {
                                                validation_mode = "value_check",
                                                min_value = 20
                                            }
                                        }
                                    },
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                            key = "filtered_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Item Pipeline Validation Node"
                                }
                            }
                        },
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = template_node_id,
                                node_type = "wippy.dataflow.node.func:node",
                                parent_node_id = map_reduce_node_id,
                                status = consts.STATUS.TEMPLATE,
                                config = {
                                    func_id = "wippy.dataflow.node.func:test_func",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.NODE_OUTPUT,
                                            key = "result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Item Pipeline Validation Template Node"
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
                                node_id = map_reduce_node_id,
                                key = input_data_id,
                                content = "",
                                content_type = "dataflow/reference"
                            }
                        }
                    }

                    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                        metadata = {
                            title = "Item Pipeline Validation Test Workflow"
                        }
                    })
                    expect(create_err).to_be_nil()

                    local result, exec_err = c:execute(dataflow_id)
                    expect(exec_err).to_be_nil()
                    expect(result.success).to_be_true()

                    local output_data = data_reader.with_dataflow(dataflow_id)
                        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                        :with_data_keys("filtered_result")
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

                    expect(output_content.success_count).to_equal(2)
                    expect(output_content.total_iterations).to_equal(3)

                    for _, success in ipairs(output_content.successes) do
                        expect(success.item.value).to_be_greater_than_or_equal(20)
                        print("✓ Item passed filter:", success.item.message, "value:", success.item.value)
                    end

                    print("=== ITEM PIPELINE VALIDATION TEST COMPLETE ===")
                end)
            end)

            describe("Reduction Pipeline Integration", function()
                it("should apply reduction pipeline with aggregation", function()
                    print("=== REDUCTION PIPELINE TEST START ===")

                    local c, err = client.new()
                    expect(err).to_be_nil()

                    local map_reduce_node_id = uuid.v7()
                    local template_node_id = uuid.v7()
                    local input_data_id = uuid.v7()
                    local node_input_id = uuid.v7()

                    local test_input = {
                        items = {
                            { message = "Item 1", value = 10 },
                            { message = "Item 2", value = 20 },
                            { message = "Item 3", value = 30 }
                        }
                    }

                    local workflow_commands = {
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = map_reduce_node_id,
                                node_type = "wippy.dataflow.node.map_reduce:map_reduce",
                                status = consts.STATUS.PENDING,
                                config = {
                                    source_array_key = "items",
                                    failure_strategy = "collect_errors",
                                    reduction_extract = "successes",
                                    reduction_steps = {
                                        {
                                            type = "map",
                                            func_id = "wippy.dataflow.node.map_reduce.stub:extract_number",
                                            context = {
                                                field = "value"
                                            }
                                        },
                                        {
                                            type = "aggregate",
                                            func_id = "wippy.dataflow.node.map_reduce.stub:calculate_stats"
                                        }
                                    },
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                            key = "reduced_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Reduction Pipeline Aggregation Node"
                                }
                            }
                        },
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = template_node_id,
                                node_type = "wippy.dataflow.node.func:node",
                                parent_node_id = map_reduce_node_id,
                                status = consts.STATUS.TEMPLATE,
                                config = {
                                    func_id = "wippy.dataflow.node.func:test_func",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.NODE_OUTPUT,
                                            key = "result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Reduction Pipeline Aggregation Template Node"
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
                                node_id = map_reduce_node_id,
                                key = input_data_id,
                                content = "",
                                content_type = "dataflow/reference"
                            }
                        }
                    }

                    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                        metadata = {
                            title = "Reduction Pipeline Aggregation Test Workflow"
                        }
                    })
                    expect(create_err).to_be_nil()

                    local result, exec_err = c:execute(dataflow_id)
                    expect(exec_err).to_be_nil()
                    expect(result.success).to_be_true()

                    local output_data = data_reader.with_dataflow(dataflow_id)
                        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                        :with_data_keys("reduced_result")
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

                    -- Use the same pattern as the working test - extract_number + calculate_stats
                    expect(output_content.sum).to_equal(60) -- 10 + 20 + 30
                    expect(output_content.count).to_equal(3)
                    expect(output_content.calculated_by).to_equal("calculate_stats")

                    print("✓ Reduction pipeline applied:")
                    print("  Total value:", output_content.sum)
                    print("  Item count:", output_content.count)
                    print("=== REDUCTION PIPELINE TEST COMPLETE ===")
                end)

                it("should apply reduction pipeline with extract and aggregate", function()
                    print("=== ADVANCED REDUCTION PIPELINE TEST START ===")

                    local c, err = client.new()
                    expect(err).to_be_nil()

                    local map_reduce_node_id = uuid.v7()
                    local template_node_id = uuid.v7()
                    local input_data_id = uuid.v7()
                    local node_input_id = uuid.v7()

                    local test_input = {
                        items = {
                            { message = "Score 1", value = 85 },
                            { message = "Score 2", value = 92 },
                            { message = "Score 3", value = 78 }
                        }
                    }

                    local workflow_commands = {
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = map_reduce_node_id,
                                node_type = "wippy.dataflow.node.map_reduce:map_reduce",
                                status = consts.STATUS.PENDING,
                                config = {
                                    source_array_key = "items",
                                    failure_strategy = "collect_errors",
                                    reduction_extract = "successes",
                                    reduction_steps = {
                                        {
                                            type = "map",
                                            func_id = "wippy.dataflow.node.map_reduce.stub:extract_number",
                                            context = {
                                                field = "value"
                                            }
                                        },
                                        {
                                            type = "aggregate",
                                            func_id = "wippy.dataflow.node.map_reduce.stub:calculate_stats",
                                            context = {
                                                include_min_max = true
                                            }
                                        },
                                        {
                                            type = "aggregate",
                                            func_id = "wippy.dataflow.node.map_reduce.stub:format_report",
                                            context = {
                                                title = "Test Scores Report",
                                                style = "summary"
                                            }
                                        }
                                    },
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                            key = "pipeline_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Advanced Reduction Pipeline Node"
                                }
                            }
                        },
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = template_node_id,
                                node_type = "wippy.dataflow.node.func:node",
                                parent_node_id = map_reduce_node_id,
                                status = consts.STATUS.TEMPLATE,
                                config = {
                                    func_id = "wippy.dataflow.node.func:test_func",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.NODE_OUTPUT,
                                            key = "result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Advanced Reduction Pipeline Template Node"
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
                                node_id = map_reduce_node_id,
                                key = input_data_id,
                                content = "",
                                content_type = "dataflow/reference"
                            }
                        }
                    }

                    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                        metadata = {
                            title = "Advanced Reduction Pipeline Test Workflow"
                        }
                    })
                    expect(create_err).to_be_nil()

                    local result, exec_err = c:execute(dataflow_id)
                    expect(exec_err).to_be_nil()
                    expect(result.success).to_be_true()

                    local output_data = data_reader.with_dataflow(dataflow_id)
                        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                        :with_data_keys("pipeline_result")
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

                    expect(output_content.title).to_equal("Test Scores Report")
                    expect(output_content.formatted_by).to_equal("format_report")
                    expect(output_content.data).not_to_be_nil()

                    local stats_data = output_content.data
                    expect(stats_data.sum).to_equal(255)    -- 85 + 92 + 78
                    expect(stats_data.count).to_equal(3)
                    expect(stats_data.average).to_equal(85) -- 255 / 3
                    expect(stats_data.min).to_equal(78)
                    expect(stats_data.max).to_equal(92)
                    expect(stats_data.calculated_by).to_equal("calculate_stats")

                    print("✓ Advanced reduction pipeline completed:")
                    print("  Title:", output_content.title)
                    print("  Sum:", stats_data.sum)
                    print("  Average:", stats_data.average)
                    print("  Min:", stats_data.min)
                    print("  Max:", stats_data.max)
                    print("=== ADVANCED REDUCTION PIPELINE TEST COMPLETE ===")
                end)
            end)

            describe("Failure Handling Integration", function()
                it("should handle fail_fast strategy correctly", function()
                    print("=== FAIL_FAST INTEGRATION TEST START ===")

                    local c, err = client.new()
                    expect(err).to_be_nil()

                    local map_reduce_node_id = uuid.v7()
                    local template_node_id = uuid.v7()
                    local input_data_id = uuid.v7()
                    local node_input_id = uuid.v7()

                    local test_input = {
                        items = {
                            { message = "Success item",    should_fail = false },
                            { message = "Failure item",    should_fail = true },
                            { message = "Never processed", should_fail = false }
                        }
                    }

                    local workflow_commands = {
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = map_reduce_node_id,
                                node_type = "wippy.dataflow.node.map_reduce:map_reduce",
                                status = consts.STATUS.PENDING,
                                config = {
                                    source_array_key = "items",
                                    batch_size = 1,
                                    failure_strategy = "fail_fast",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                            key = "fail_fast_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Fail Fast Strategy Node"
                                }
                            }
                        },
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = template_node_id,
                                node_type = "wippy.dataflow.node.func:node",
                                parent_node_id = map_reduce_node_id,
                                status = consts.STATUS.TEMPLATE,
                                config = {
                                    func_id = "wippy.dataflow.node.func:test_func",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.NODE_OUTPUT,
                                            key = "result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Fail Fast Strategy Template Node"
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
                                node_id = map_reduce_node_id,
                                key = input_data_id,
                                content = "",
                                content_type = "dataflow/reference"
                            }
                        }
                    }

                    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                        metadata = {
                            title = "Fail Fast Strategy Test Workflow"
                        }
                    })
                    expect(create_err).to_be_nil()

                    local result, exec_err = c:execute(dataflow_id)
                    expect(exec_err).to_be_nil()

                    expect(result.success).to_be_false()
                    expect(result.error).to_contain("Iteration failed")

                    print("✓ Fail_fast strategy correctly failed the workflow")
                    print("=== FAIL_FAST INTEGRATION TEST COMPLETE ===")
                end)

                it("should handle collect_errors strategy correctly", function()
                    print("=== COLLECT_ERRORS INTEGRATION TEST START ===")

                    local c, err = client.new()
                    expect(err).to_be_nil()

                    local map_reduce_node_id = uuid.v7()
                    local template_node_id = uuid.v7()
                    local input_data_id = uuid.v7()
                    local node_input_id = uuid.v7()

                    local test_input = {
                        items = {
                            { message = "Success item 1", should_fail = false },
                            { message = "Failure item",   should_fail = true },
                            { message = "Success item 2", should_fail = false }
                        }
                    }

                    local workflow_commands = {
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = map_reduce_node_id,
                                node_type = "wippy.dataflow.node.map_reduce:map_reduce",
                                status = consts.STATUS.PENDING,
                                config = {
                                    source_array_key = "items",
                                    batch_size = 1,
                                    failure_strategy = "collect_errors",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.WORKFLOW_OUTPUT,
                                            key = "collect_errors_result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Collect Errors Strategy Node"
                                }
                            }
                        },
                        {
                            type = consts.COMMAND_TYPES.CREATE_NODE,
                            payload = {
                                node_id = template_node_id,
                                node_type = "wippy.dataflow.node.func:node",
                                parent_node_id = map_reduce_node_id,
                                status = consts.STATUS.TEMPLATE,
                                config = {
                                    func_id = "wippy.dataflow.node.func:test_func",
                                    data_targets = {
                                        {
                                            data_type = consts.DATA_TYPE.NODE_OUTPUT,
                                            key = "result"
                                        }
                                    }
                                },
                                metadata = {
                                    title = "Collect Errors Strategy Template Node"
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
                                node_id = map_reduce_node_id,
                                key = input_data_id,
                                content = "",
                                content_type = "dataflow/reference"
                            }
                        }
                    }

                    local dataflow_id, create_err = c:create_workflow(workflow_commands, {
                        metadata = {
                            title = "Collect Errors Strategy Test Workflow"
                        }
                    })
                    expect(create_err).to_be_nil()

                    local result, exec_err = c:execute(dataflow_id)
                    expect(exec_err).to_be_nil()
                    expect(result.success).to_be_true()

                    local output_data = data_reader.with_dataflow(dataflow_id)
                        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
                        :with_data_keys("collect_errors_result")
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

                    expect(output_content.success_count).to_equal(2)
                    expect(output_content.failure_count).to_equal(1)
                    expect(output_content.total_iterations).to_equal(3)

                    print("✓ Collect_errors strategy processed all items:")
                    print("  Successes:", output_content.success_count)
                    print("  Failures:", output_content.failure_count)
                    print("=== COLLECT_ERRORS INTEGRATION TEST COMPLETE ===")
                end)
            end)
        end)
end

return test.run_cases(define_tests)
