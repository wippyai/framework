local test = require("test")
local uuid = require("uuid")
local json = require("json")
local time = require("time")
local sql = require("sql")
local security = require("security")

local node_reader = require("node_reader")

local function define_tests()
    local test_dataflow_id
    local test_node_ids = {}
    local test_parent_node_id

    describe("Node Reader", function()
        local function get_test_db()
            local db, err = sql.get("app:db")
            if err then error("Failed to connect to database: " .. err) end
            return db
        end

        before_all(function()
            local db = get_test_db()
            local tx, err_tx = db:begin()
            if err_tx then
                db:release(); error("Failed to begin transaction: " .. err_tx)
            end

            local now_ts = time.now():format(time.RFC3339)

            test_dataflow_id = uuid.v7()
            local test_actor_id = "test-actor-" .. uuid.v7()

            local dataflow_result, wf_err = tx:execute([[
                INSERT INTO dataflows (
                    dataflow_id, actor_id, type, status, metadata, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ]], {
                test_dataflow_id,
                test_actor_id,
                "node_reader_test",
                "active",
                "{}",
                now_ts,
                now_ts
            })

            if wf_err then
                tx:rollback()
                db:release()
                error("Failed to create test dataflow: " .. wf_err)
            end

            local test_nodes = {
                {
                    node_id = uuid.v7(),
                    parent_node_id = nil,
                    type = "root_node",
                    status = "pending",
                    config = {
                        timeout = 30,
                        retries = 3,
                        mode = "strict"
                    },
                    metadata = {
                        source = "test",
                        category = "root"
                    }
                },
                {
                    node_id = uuid.v7(),
                    parent_node_id = nil,
                    type = "template_node",
                    status = "template",
                    config = {
                        func_id = "test_function",
                        data_targets = {
                            {
                                data_type = "node.output",
                                key = "result"
                            }
                        }
                    },
                    metadata = {
                        template_type = "function_executor",
                        version = "1.0"
                    }
                },
                {
                    node_id = uuid.v7(),
                    parent_node_id = nil,
                    type = "func_node",
                    status = "running",
                    config = {
                        func_id = "active_function",
                        timeout = 60
                    },
                    metadata = {
                        started_at = now_ts,
                        worker_id = "worker_123"
                    }
                },
                {
                    node_id = uuid.v7(),
                    parent_node_id = nil,
                    type = "func_node",
                    status = "completed",
                    config = {
                        func_id = "completed_function"
                    },
                    metadata = {
                        completed_at = now_ts,
                        duration_ms = 1500
                    }
                },
                {
                    node_id = uuid.v7(),
                    parent_node_id = nil,
                    type = "func_node",
                    status = "failed",
                    config = {},
                    metadata = {
                        error = "Function execution failed",
                        failed_at = now_ts
                    }
                },
                {
                    node_id = uuid.v7(),
                    parent_node_id = nil,
                    type = "minimal_node",
                    status = "pending",
                    config = "",
                    metadata = ""
                },
                {
                    node_id = uuid.v7(),
                    parent_node_id = nil,
                    type = "invalid_json_node",
                    status = "pending",
                    config = '{"invalid":json}',
                    metadata = '{"invalid":metadata}'
                }
            }

            for i, node_spec in ipairs(test_nodes) do
                local node_id = node_spec.node_id
                test_node_ids[node_spec.type] = node_id

                local parent_id = nil
                if i > 1 and i <= 5 then
                    parent_id = test_node_ids["root_node"]
                    if i == 2 then
                        test_parent_node_id = test_node_ids["root_node"]
                    end
                end

                local config_json = "{}"
                if node_spec.config then
                    if type(node_spec.config) == "table" then
                        local encoded, err_encode = json.encode(node_spec.config)
                        if not err_encode then
                            config_json = encoded
                        end
                    elseif type(node_spec.config) == "string" then
                        config_json = node_spec.config
                    end
                end

                local metadata_json = "{}"
                if node_spec.metadata then
                    if type(node_spec.metadata) == "table" then
                        local encoded, err_encode = json.encode(node_spec.metadata)
                        if not err_encode then
                            metadata_json = encoded
                        end
                    elseif type(node_spec.metadata) == "string" then
                        metadata_json = node_spec.metadata
                    end
                end

                local node_result, node_err = tx:execute([[
                    INSERT INTO nodes (
                        node_id, dataflow_id, parent_node_id, type, status, config, metadata, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ]], {
                    node_id,
                    test_dataflow_id,
                    parent_id,
                    node_spec.type,
                    node_spec.status,
                    config_json,
                    metadata_json,
                    now_ts,
                    now_ts
                })

                if node_err then
                    tx:rollback()
                    db:release()
                    error("Failed to create test node: " .. node_err)
                end
            end

            local commit_result, commit_err = tx:commit()
            if commit_err then
                tx:rollback()
                db:release()
                error("Failed to commit test data: " .. commit_err)
            end

            db:release()
        end)

        after_all(function()
            local db = get_test_db()
            local tx, err_tx = db:begin()
            if err_tx then
                print("ERROR: Failed to begin cleanup transaction"); db:release(); return
            end

            local del_result, del_err = tx:execute("DELETE FROM dataflows WHERE dataflow_id = ?", { test_dataflow_id })
            if del_err then
                tx:rollback()
                db:release()
                print("ERROR: Failed to clean up test data: " .. del_err)
                return
            end

            local commit_result, commit_err = tx:commit()
            if commit_err then
                tx:rollback()
                db:release()
                print("ERROR: Failed to commit cleanup: " .. commit_err)
                return
            end

            db:release()
        end)

        describe("Basic Operations", function()
            it("should initialize with a dataflow ID", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()
                expect(reader).not_to_be_nil()
            end)

            it("should return error when initialized without a dataflow ID", function()
                local reader1, err1 = node_reader.with_dataflow(nil)
                expect(reader1).to_be_nil()
                expect(err1).to_contain("Workflow ID is required")

                local reader2, err2 = node_reader.with_dataflow("")
                expect(reader2).to_be_nil()
                expect(err2).to_contain("Workflow ID is required")
            end)

            it("should return all nodes for a dataflow", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader:all()
                expect(query_err).to_be_nil()
                expect(#results).to_equal(7)

                expect(results[1].config).to_be_type("table")
                expect(results[1].metadata).to_be_type("table")
            end)

            it("should count all nodes for a dataflow", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local count, query_err = reader:count()
                expect(query_err).to_be_nil()
                expect(count).to_equal(7)
            end)

            it("should check existence of nodes", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local exists, query_err = reader:exists()
                expect(query_err).to_be_nil()
                expect(exists).to_be_true()

                local reader2, err2 = node_reader.with_dataflow(uuid.v7())
                expect(err2).to_be_nil()

                local non_exists, query_err2 = reader2:exists()
                expect(query_err2).to_be_nil()
                expect(non_exists).to_be_false()
            end)
        end)

        describe("Filtering", function()
            it("should filter by node ID", function()
                local root_node_id = test_node_ids["root_node"]
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_nodes(root_node_id)
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(1)
                expect(results[1].node_id).to_equal(root_node_id)
                expect(results[1].type).to_equal("root_node")
            end)

            it("should filter by multiple node IDs", function()
                local root_id = test_node_ids["root_node"]
                local template_id = test_node_ids["template_node"]

                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_nodes(root_id, template_id)
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(2)
                local found_types = {}
                for _, node in ipairs(results) do
                    found_types[node.type] = true
                end
                expect(found_types["root_node"]).to_be_true()
                expect(found_types["template_node"]).to_be_true()
            end)

            it("should filter by node type", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_node_types("func_node")
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(3)
                for _, node in ipairs(results) do
                    expect(node.type).to_equal("func_node")
                end
            end)

            it("should filter by multiple node types", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_node_types("root_node", "template_node")
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(2)
                for _, node in ipairs(results) do
                    expect(node.type == "root_node" or node.type == "template_node").to_be_true()
                end
            end)

            it("should filter by status", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_statuses("pending")
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(3)
                for _, node in ipairs(results) do
                    expect(node.status).to_equal("pending")
                end
            end)

            it("should filter by multiple statuses", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_statuses("running", "completed")
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(2)
                for _, node in ipairs(results) do
                    expect(node.status == "running" or node.status == "completed").to_be_true()
                end
            end)

            it("should filter by parent node ID", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_parent_nodes(test_parent_node_id)
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(4)
                for _, node in ipairs(results) do
                    expect(node.parent_node_id).to_equal(test_parent_node_id)
                end
            end)

            it("should filter by multiple parent node IDs", function()
                local fake_parent_id = uuid.v7()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_parent_nodes(test_parent_node_id, fake_parent_id)
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(4)
                for _, node in ipairs(results) do
                    expect(node.parent_node_id).to_equal(test_parent_node_id)
                end
            end)

            it("should combine multiple filters", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :with_parent_nodes(test_parent_node_id)
                    :with_node_types("func_node")
                    :with_statuses("running", "completed")
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_equal(2)
                for _, node in ipairs(results) do
                    expect(node.type).to_equal("func_node")
                    expect(node.parent_node_id).to_equal(test_parent_node_id)
                    expect(node.status == "running" or node.status == "completed").to_be_true()
                end
            end)
        end)

        describe("Fetch Options", function()
            it("should exclude config when specified", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :fetch_options({ config = false })
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_be_greater_than(0)
                for _, node in ipairs(results) do
                    expect(node.config).to_be_nil()
                end
            end)

            it("should exclude metadata when specified", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :fetch_options({ metadata = false })
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_be_greater_than(0)
                for _, node in ipairs(results) do
                    expect(node.metadata).to_be_nil()
                end
            end)

            it("should fetch only basic fields when config and metadata excluded", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local results, query_err = reader
                    :fetch_options({ config = false, metadata = false })
                    :all()
                expect(query_err).to_be_nil()

                expect(#results).to_be_greater_than(0)
                for _, node in ipairs(results) do
                    expect(node.node_id).not_to_be_nil()
                    expect(node.type).not_to_be_nil()
                    expect(node.status).not_to_be_nil()
                    expect(node.config).to_be_nil()
                    expect(node.metadata).to_be_nil()
                end
            end)
        end)

        describe("One Result", function()
            it("should fetch a single result", function()
                local root_node_id = test_node_ids["root_node"]
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local node, query_err = reader
                    :with_nodes(root_node_id)
                    :one()
                expect(query_err).to_be_nil()

                expect(node).not_to_be_nil()
                expect(node.node_id).to_equal(root_node_id)
                expect(node.type).to_equal("root_node")
                expect(node.config).to_be_type("table")
                expect(node.metadata).to_be_type("table")
            end)

            it("should return nil for non-matching query", function()
                local fake_node_id = uuid.v7()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local node, query_err = reader
                    :with_nodes(fake_node_id)
                    :one()
                expect(query_err).to_be_nil()
                expect(node).to_be_nil()
            end)

            it("should respect fetch options", function()
                local root_node_id = test_node_ids["root_node"]
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local node, query_err = reader
                    :with_nodes(root_node_id)
                    :fetch_options({ config = false })
                    :one()
                expect(query_err).to_be_nil()

                expect(node).not_to_be_nil()
                expect(node.node_id).to_equal(root_node_id)
                expect(node.config).to_be_nil()
                expect(node.metadata).to_be_type("table")
            end)
        end)

        describe("JSON Parsing", function()
            it("should parse complex config correctly", function()
                local template_node_id = test_node_ids["template_node"]
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local node, query_err = reader
                    :with_nodes(template_node_id)
                    :one()
                expect(query_err).to_be_nil()

                expect(node).not_to_be_nil()
                expect(node.config).to_be_type("table")
                expect(node.config.func_id).to_equal("test_function")
                expect(node.config.data_targets).to_be_type("table")
                expect(#node.config.data_targets).to_equal(1)
                expect(node.config.data_targets[1].data_type).to_equal("node.output")
                expect(node.config.data_targets[1].key).to_equal("result")

                expect(node.metadata).to_be_type("table")
                expect(node.metadata.template_type).to_equal("function_executor")
                expect(node.metadata.version).to_equal("1.0")
            end)

            it("should handle empty string config/metadata", function()
                local minimal_node_id = test_node_ids["minimal_node"]
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local node, query_err = reader
                    :with_nodes(minimal_node_id)
                    :one()
                expect(query_err).to_be_nil()

                expect(node).not_to_be_nil()
                expect(node.config).to_be_type("table")
                expect(next(node.config)).to_be_nil()
                expect(node.metadata).to_be_type("table")
                expect(next(node.metadata)).to_be_nil()
            end)

            it("should handle invalid JSON gracefully", function()
                local invalid_node_id = test_node_ids["invalid_json_node"]
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local node, query_err = reader
                    :with_nodes(invalid_node_id)
                    :one()
                expect(query_err).to_be_nil()

                expect(node).not_to_be_nil()
                expect(node.config).to_be_type("table")
                expect(next(node.config)).to_be_nil()
                expect(node.metadata).to_be_type("table")
                expect(next(node.metadata)).to_be_nil()
            end)
        end)

        describe("Template Node Discovery", function()
            it("should find template nodes by status", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local templates, query_err = reader
                    :with_statuses("template")
                    :all()
                expect(query_err).to_be_nil()

                expect(#templates).to_equal(1)
                expect(templates[1].status).to_equal("template")
                expect(templates[1].type).to_equal("template_node")
            end)

            it("should find template children of a specific parent", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local templates, query_err = reader
                    :with_parent_nodes(test_parent_node_id)
                    :with_statuses("template")
                    :all()
                expect(query_err).to_be_nil()

                expect(#templates).to_equal(1)
                expect(templates[1].status).to_equal("template")
                expect(templates[1].parent_node_id).to_equal(test_parent_node_id)
                expect(templates[1].config.func_id).to_equal("test_function")
            end)

            it("should find all children of a parent node", function()
                local reader, err = node_reader.with_dataflow(test_dataflow_id)
                expect(err).to_be_nil()

                local children, query_err = reader
                    :with_parent_nodes(test_parent_node_id)
                    :all()
                expect(query_err).to_be_nil()

                expect(#children).to_equal(4)
                for _, child in ipairs(children) do
                    expect(child.parent_node_id).to_equal(test_parent_node_id)
                end

                local statuses = {}
                for _, child in ipairs(children) do
                    statuses[child.status] = true
                end
                expect(statuses["template"]).to_be_true()
                expect(statuses["running"]).to_be_true()
                expect(statuses["completed"]).to_be_true()
                expect(statuses["failed"]).to_be_true()
            end)
        end)
    end)
end

return test.run_cases(define_tests)