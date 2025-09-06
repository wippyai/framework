local test = require("test")
local uuid = require("uuid")
local json = require("json")
local time = require("time")
local sql = require("sql")
local security = require("security")
local dataflow_repo = require("dataflow_repo")

local function define_tests()
    describe("Workflow Repository", function()
        local test_actor_id_global_scope = uuid.v7() -- For items not related to isolated list tests
        local actor = security.actor()
        if actor then
            test_actor_id_global_scope = actor:id()
        end

        local created_dataflow_ids_for_global_cleanup = {}

        local function register_for_global_cleanup(id)
            if id then
                local found = false
                for _, existing_id in ipairs(created_dataflow_ids_for_global_cleanup) do
                    if existing_id == id then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(created_dataflow_ids_for_global_cleanup, id)
                end
            end
        end

        after_all(function()
            if #created_dataflow_ids_for_global_cleanup == 0 then return end
            local db, err_db = sql.get("app:db")
            if err_db then print("ERROR (global after_all): DB connect failed: " .. err_db) return end
            local tx, err_tx = db:begin()
            if err_tx then print("ERROR (global after_all): Transaction begin failed: " .. err_tx); db:release(); return end
            local success_all = true
            for i = #created_dataflow_ids_for_global_cleanup, 1, -1 do
                local id_to_delete = created_dataflow_ids_for_global_cleanup[i]
                local _, err_delete = tx:execute("DELETE FROM dataflows WHERE dataflow_id = $1", { id_to_delete })
                if err_delete then
                    print("ERROR (global after_all): Delete failed for " .. id_to_delete .. ": " .. err_delete)
                    success_all = false
                end
            end
            if success_all then
                local _, err_commit = tx:commit()
                if err_commit then print("ERROR (global after_all): Commit failed: " .. err_commit); tx:rollback() end
            else
                tx:rollback()
                print("WARN (global after_all): Rolled back cleanup due to errors.")
            end
            db:release()
            created_dataflow_ids_for_global_cleanup = {}
        end)

        -- Helper function to create dataflows for testing
        local function create_test_dataflow(dataflow_id, actor_id, type_val, params)
            params = params or {}
            local db, err_db = sql.get("app:db")
            if err_db then return nil, "DB connection failed: " .. err_db end

            local tx, err_tx = db:begin()
            if err_tx then
                db:release()
                return nil, "Transaction begin failed: " .. err_tx
            end

            local now_ts = time.now():format(time.RFC3339)
            local metadata_json = "{}"

            if params.metadata then
                if type(params.metadata) == "table" then
                    local encoded, err_json = json.encode(params.metadata)
                    if not err_json then
                        metadata_json = encoded
                    end
                elseif type(params.metadata) == "string" then
                    metadata_json = params.metadata
                end
            end

            local success, err_insert = tx:execute([[
                INSERT INTO dataflows (
                    dataflow_id, parent_dataflow_id, actor_id, type, status, metadata, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                dataflow_id,
                params.parent_dataflow_id or sql.as.null(),
                actor_id,
                type_val,
                params.status or "pending",
                metadata_json,
                now_ts,
                now_ts
            })

            if err_insert then
                tx:rollback()
                db:release()
                return nil, "Failed to insert dataflow: " .. err_insert
            end

            local commit_err
            _, commit_err = tx:commit()
            if commit_err then
                tx:rollback()
                db:release()
                return nil, "Commit failed: " .. commit_err
            end

            db:release()
            register_for_global_cleanup(dataflow_id)

            return dataflow_repo.get(dataflow_id)
        end

        -- Helper function to create test nodes
        local function create_test_node(node_id, dataflow_id, node_type, params)
            params = params or {}
            local db, err_db = sql.get("app:db")
            if err_db then return nil, "DB connection failed: " .. err_db end

            local tx, err_tx = db:begin()
            if err_tx then
                db:release()
                return nil, "Transaction begin failed: " .. err_tx
            end

            local now_ts = time.now():format(time.RFC3339)

            local metadata_json = "{}"
            if params.metadata then
                if type(params.metadata) == "table" then
                    local encoded, err_json = json.encode(params.metadata)
                    if not err_json then
                        metadata_json = encoded
                    end
                elseif type(params.metadata) == "string" then
                    metadata_json = params.metadata
                end
            end

            local config_json = "{}"
            if params.config then
                if type(params.config) == "table" then
                    local encoded, err_json = json.encode(params.config)
                    if not err_json then
                        config_json = encoded
                    end
                elseif type(params.config) == "string" then
                    config_json = params.config
                end
            end

            local success, err_insert = tx:execute([[
                INSERT INTO nodes (
                    node_id, dataflow_id, parent_node_id, type, status, config, metadata, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                node_id,
                dataflow_id,
                params.parent_node_id or sql.as.null(),
                node_type,
                params.status or "pending",
                config_json,
                metadata_json,
                now_ts,
                now_ts
            })

            if err_insert then
                tx:rollback()
                db:release()
                return nil, "Failed to insert node: " .. err_insert
            end

            local commit_err
            _, commit_err = tx:commit()
            if commit_err then
                tx:rollback()
                db:release()
                return nil, "Commit failed: " .. commit_err
            end

            db:release()
            return true, nil
        end

        describe("Read (Get) Operations", function()
            local wf_id_get; local get_metadata = { data = "to_get" }
            before_all(function()
                wf_id_get = uuid.v7()
                local wf, err = create_test_dataflow(wf_id_get, test_actor_id_global_scope, "get_test_type",
                    { metadata = get_metadata })
                expect(err).to_be_nil()
                expect(wf).not_to_be_nil()
            end)

            it("should get an existing dataflow by ID", function()
                local wf, err = dataflow_repo.get(wf_id_get)
                expect(err).to_be_nil(); expect(wf).not_to_be_nil()
                expect(wf.dataflow_id).to_equal(wf_id_get);
                expect(wf.metadata.data).to_equal(get_metadata.data)
            end)

            it("should return error for non-existent dataflow ID", function()
                local _, err = dataflow_repo.get(uuid.v7()); expect(err).to_contain("Workflow not found")
            end)

            it("should return error for nil or empty dataflow ID", function()
                local _, err = dataflow_repo.get(nil); expect(err).to_contain("Workflow ID is required")
                _, err = dataflow_repo.get(""); expect(err).to_contain("Workflow ID is required")
            end)
        end)

        describe("Node Loading Operations", function()
            local nodes_test_dataflow_id
            local node_ids = {}

            before_all(function()
                nodes_test_dataflow_id = uuid.v7()

                -- Create test dataflow
                local wf, err = create_test_dataflow(nodes_test_dataflow_id, test_actor_id_global_scope, "nodes_test_type")
                expect(err).to_be_nil()
                expect(wf).not_to_be_nil()

                -- Create test nodes with various config scenarios
                local test_nodes = {
                    {
                        id = uuid.v7(),
                        type = "minimal_node",
                        params = {} -- Empty config and metadata
                    },
                    {
                        id = uuid.v7(),
                        type = "complex_config_node",
                        params = {
                            config = {
                                timeout = 30,
                                retries = 3,
                                endpoints = {"api1.example.com", "api2.example.com"},
                                settings = {
                                    debug = true,
                                    verbose = false
                                }
                            },
                            metadata = {
                                created_by = "test",
                                version = "1.0"
                            }
                        }
                    },
                    {
                        id = uuid.v7(),
                        type = "json_string_config_node",
                        params = {
                            config = '{"batch_size":100,"parallel":true,"features":["logging","metrics"]}',
                            metadata = '{"source":"json_test","tags":["test","config"]}'
                        }
                    },
                    {
                        id = uuid.v7(),
                        type = "invalid_json_config_node",
                        params = {
                            config = '{"invalid":json}', -- Invalid JSON
                            metadata = '{"invalid":metadata}' -- Invalid JSON
                        }
                    },
                    {
                        id = uuid.v7(),
                        type = "empty_string_config_node",
                        params = {
                            config = "",
                            metadata = ""
                        }
                    }
                }

                for _, test_node in ipairs(test_nodes) do
                    local success, err_node = create_test_node(test_node.id, nodes_test_dataflow_id, test_node.type, test_node.params)
                    expect(err_node).to_be_nil()
                    expect(success).to_be_true()
                    table.insert(node_ids, test_node.id)
                end
            end)

            it("should get nodes for dataflow and parse config correctly", function()
                local nodes, err = dataflow_repo.get_nodes_for_dataflow(nodes_test_dataflow_id)

                expect(err).to_be_nil()
                expect(nodes).not_to_be_nil()
                expect(#nodes).to_equal(5)

                -- Sort nodes by type for predictable testing
                table.sort(nodes, function(a, b) return a.type < b.type end)

                -- Test complex config node
                local complex_node = nil
                for _, node in ipairs(nodes) do
                    if node.type == "complex_config_node" then
                        complex_node = node
                        break
                    end
                end

                expect(complex_node).not_to_be_nil()
                expect(complex_node.config).to_be_type("table")
                expect(complex_node.config.timeout).to_equal(30)
                expect(complex_node.config.retries).to_equal(3)
                expect(complex_node.config.endpoints).to_be_type("table")
                expect(#complex_node.config.endpoints).to_equal(2)
                expect(complex_node.config.endpoints[1]).to_equal("api1.example.com")
                expect(complex_node.config.settings).to_be_type("table")
                expect(complex_node.config.settings.debug).to_be_true()
                expect(complex_node.config.settings.verbose).to_be_false()

                expect(complex_node.metadata).to_be_type("table")
                expect(complex_node.metadata.created_by).to_equal("test")
                expect(complex_node.metadata.version).to_equal("1.0")
            end)

            it("should parse JSON string config correctly", function()
                local nodes, err = dataflow_repo.get_nodes_for_dataflow(nodes_test_dataflow_id)
                expect(err).to_be_nil()

                local json_node = nil
                for _, node in ipairs(nodes) do
                    if node.type == "json_string_config_node" then
                        json_node = node
                        break
                    end
                end

                expect(json_node).not_to_be_nil()
                expect(json_node.config).to_be_type("table")
                expect(json_node.config.batch_size).to_equal(100)
                expect(json_node.config.parallel).to_be_true()
                expect(json_node.config.features).to_be_type("table")
                expect(#json_node.config.features).to_equal(2)
                expect(json_node.config.features[1]).to_equal("logging")
                expect(json_node.config.features[2]).to_equal("metrics")

                expect(json_node.metadata).to_be_type("table")
                expect(json_node.metadata.source).to_equal("json_test")
                expect(json_node.metadata.tags).to_be_type("table")
                expect(#json_node.metadata.tags).to_equal(2)
            end)

            it("should handle minimal node with empty config", function()
                local nodes, err = dataflow_repo.get_nodes_for_dataflow(nodes_test_dataflow_id)
                expect(err).to_be_nil()

                local minimal_node = nil
                for _, node in ipairs(nodes) do
                    if node.type == "minimal_node" then
                        minimal_node = node
                        break
                    end
                end

                expect(minimal_node).not_to_be_nil()
                expect(minimal_node.config).to_be_type("table")
                expect(next(minimal_node.config)).to_be_nil() -- Empty table
                expect(minimal_node.metadata).to_be_type("table")
                expect(next(minimal_node.metadata)).to_be_nil() -- Empty table
            end)

            it("should handle invalid JSON gracefully", function()
                local nodes, err = dataflow_repo.get_nodes_for_dataflow(nodes_test_dataflow_id)
                expect(err).to_be_nil()

                local invalid_node = nil
                for _, node in ipairs(nodes) do
                    if node.type == "invalid_json_config_node" then
                        invalid_node = node
                        break
                    end
                end

                expect(invalid_node).not_to_be_nil()
                -- Invalid JSON should default to empty table
                expect(invalid_node.config).to_be_type("table")
                expect(next(invalid_node.config)).to_be_nil() -- Empty table
                expect(invalid_node.metadata).to_be_type("table")
                expect(next(invalid_node.metadata)).to_be_nil() -- Empty table
            end)

            it("should handle empty string config", function()
                local nodes, err = dataflow_repo.get_nodes_for_dataflow(nodes_test_dataflow_id)
                expect(err).to_be_nil()

                local empty_node = nil
                for _, node in ipairs(nodes) do
                    if node.type == "empty_string_config_node" then
                        empty_node = node
                        break
                    end
                end

                expect(empty_node).not_to_be_nil()
                expect(empty_node.config).to_be_type("table")
                expect(next(empty_node.config)).to_be_nil() -- Empty table
                expect(empty_node.metadata).to_be_type("table")
                expect(next(empty_node.metadata)).to_be_nil() -- Empty table
            end)

            it("should return error for missing dataflow ID", function()
                local nodes, err = dataflow_repo.get_nodes_for_dataflow(nil)
                expect(nodes).to_be_nil()
                expect(err).to_contain("Workflow ID is required")

                nodes, err = dataflow_repo.get_nodes_for_dataflow("")
                expect(nodes).to_be_nil()
                expect(err).to_contain("Workflow ID is required")
            end)

            it("should return empty array for dataflow with no nodes", function()
                local empty_dataflow_id = uuid.v7()
                local wf, err = create_test_dataflow(empty_dataflow_id, test_actor_id_global_scope, "empty_nodes_test")
                expect(err).to_be_nil()

                local nodes, err_nodes = dataflow_repo.get_nodes_for_dataflow(empty_dataflow_id)
                expect(err_nodes).to_be_nil()
                expect(nodes).to_be_type("table")
                expect(#nodes).to_equal(0)
            end)

            it("should return error for non-existent dataflow", function()
                local fake_dataflow_id = uuid.v7()
                local nodes, err = dataflow_repo.get_nodes_for_dataflow(fake_dataflow_id)
                expect(err).to_be_nil() -- Function doesn't validate dataflow exists
                expect(nodes).to_be_type("table")
                expect(#nodes).to_equal(0) -- Just returns empty array
            end)
        end)

        describe("List Operations", function()
            local list_operations_actor_id = uuid.v7()
            local user1_id = list_operations_actor_id
            local user2_id = uuid.v7()
            local list_parent_id = uuid.v7()
            local list_suite_temp_created_ids = {} -- For specific cleanup for this suite if needed

            before_all(function()
                -- Create parent dataflow
                local p_wf, p_err = create_test_dataflow(list_parent_id, user1_id, "list_parent_type")
                expect(p_err).to_be_nil()
                table.insert(list_suite_temp_created_ids, list_parent_id)

                -- Create test dataflows for listing tests
                local items = {
                    { id = uuid.v7(), actor_id = user1_id, type = "typeA", status = "pending" },
                    { id = uuid.v7(), actor_id = user1_id, type = "typeA", status = "completed" },
                    { id = uuid.v7(), actor_id = user1_id, type = "typeB", status = "pending" },
                    { id = uuid.v7(), actor_id = user1_id, type = "typeB", status = "running", parent_dataflow_id = list_parent_id },
                    { id = uuid.v7(), actor_id = user2_id, type = "typeA", status = "pending" },
                }

                for _, item_spec in ipairs(items) do
                    local _, err_create = create_test_dataflow(item_spec.id, item_spec.actor_id, item_spec.type, {
                        status = item_spec.status,
                        parent_dataflow_id = item_spec.parent_dataflow_id
                    })
                    expect(err_create).to_be_nil()
                    table.insert(list_suite_temp_created_ids, item_spec.id)
                end
            end)

            it("should list dataflows by actor_id", function()
                local wfs, err = dataflow_repo.list_by_user(user1_id)
                expect(err).to_be_nil()
                expect(#wfs).to_equal(5) -- parent + 3 roots for U1 + 1 child for U1
                for _, wf in ipairs(wfs) do expect(wf.actor_id).to_equal(user1_id) end
            end)

            it("should list by actor_id with status filter", function()
                local wfs, err = dataflow_repo.list_by_user(user1_id, { status = "pending" })
                expect(err).to_be_nil()
                expect(#wfs).to_equal(3) -- parent(pending) + U1-A-Pend-Root + U1-B-Pend-Root
                for _, wf in ipairs(wfs) do expect(wf.status).to_equal("pending") end
            end)

            it("should list by actor_id with type filter", function()
                local wfs, err = dataflow_repo.list_by_user(user1_id, { type = "typeA" })
                expect(err).to_be_nil()
                expect(#wfs).to_equal(2) -- U1-A-Pend-Root + U1-A-Comp-Root
                for _, wf in ipairs(wfs) do expect(wf.type).to_equal("typeA") end
            end)

            it("should list by actor_id with parent_dataflow_id filter (specific parent)", function()
                local wfs, err = dataflow_repo.list_by_user(user1_id, { parent_dataflow_id = list_parent_id })
                expect(err).to_be_nil()
                expect(#wfs).to_equal(1)
            end)

            it("should list by actor_id with parent_dataflow_id filter (NULL for root)", function()
                local wfs, err = dataflow_repo.list_by_user(user1_id, { parent_dataflow_id = "NULL" })
                expect(err).to_be_nil()
                expect(#wfs).to_equal(4) -- parent + 3 U1 roots
                for _, wf in ipairs(wfs) do expect(wf.parent_dataflow_id).to_be_nil() end
            end)

            it("should list by actor_id with limit and offset", function()
                local wfs_all_u1, _ = dataflow_repo.list_by_user(user1_id)
                local total_u1 = #wfs_all_u1
                local wfs_p1, _ = dataflow_repo.list_by_user(user1_id, { limit = 2 })
                expect(#wfs_p1).to_equal(2)
                if total_u1 > 2 then
                    local wfs_p2, _ = dataflow_repo.list_by_user(user1_id, { limit = 2, offset = 2 })
                    expect(#wfs_p2).to_equal(math.min(2, total_u1 - 2))
                    expect(wfs_p1[1].dataflow_id).not_to_equal(wfs_p2[1].dataflow_id)
                end
            end)

            it("should list children of a parent dataflow", function()
                local children, err = dataflow_repo.list_children(list_parent_id)
                expect(err).to_be_nil(); expect(#children).to_equal(1)
            end)

            it("should return empty list for user with no dataflows", function()
                local wfs, err = dataflow_repo.list_by_user(uuid.v7())
                expect(err).to_be_nil(); expect(#wfs).to_equal(0)
            end)
        end)
    end)
end

return test.run_cases(define_tests)