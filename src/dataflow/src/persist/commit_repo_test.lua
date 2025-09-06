local test = require("test")
local uuid = require("uuid")
local json = require("json")
local time = require("time")
local sql = require("sql")
local commit_repo = require("commit_repo")

local function define_tests()
    describe("Commit Repository", function()
        -- Test context to track resources across all tests
        local test_ctx = {
            db = nil,
            tx = nil,
            dataflow_id = nil,
            cleanup_ids = {}
        }

        -- Setup before all tests
        before_all(function()
            -- Create a test dataflow
            local db, err_db = sql.get("app:db")
            if err_db then error("Failed to connect to database: " .. err_db) end

            local tx, err_tx = db:begin()
            if err_tx then
                db:release()
                error("Failed to begin transaction: " .. err_tx)
            end

            local dataflow_id = uuid.v7()
            test_ctx.dataflow_id = dataflow_id

            local now_ts = time.now():format(time.RFC3339)

            -- Insert test dataflow
            local success, err_insert = tx:execute([[
                INSERT INTO dataflows (
                    dataflow_id, actor_id, type, status, metadata, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ]], {
                dataflow_id,
                "test-user",
                "commit_test_type",
                "active",
                "{}",
                now_ts,
                now_ts
            })

            if err_insert then
                tx:rollback()
                db:release()
                error("Failed to create test dataflow: " .. err_insert)
            end

            local _, err_commit = tx:commit()
            if err_commit then
                tx:rollback()
                db:release()
                error("Failed to commit transaction: " .. err_commit)
            end

            db:release()

            table.insert(test_ctx.cleanup_ids, dataflow_id)
        end)

        -- Cleanup after all tests
        after_all(function()
            if #test_ctx.cleanup_ids == 0 then return end

            local db, err_db = sql.get("app:db")
            if err_db then
                print("WARNING: Failed to connect to database for cleanup: " .. err_db)
                return
            end

            local tx, err_tx = db:begin()
            if err_tx then
                print("WARNING: Failed to begin transaction for cleanup: " .. err_tx)
                db:release()
                return
            end

            -- Delete test dataflows
            for _, id in ipairs(test_ctx.cleanup_ids) do
                tx:execute("DELETE FROM dataflows WHERE dataflow_id = ?", {id})
            end

            tx:commit()
            db:release()
        end)

        describe("Create operations", function()
            it("should create a commit with minimal fields", function()
                local commit_id = uuid.v7()
                local payload = { command = "test_command" }

                local commit, err = commit_repo.create(commit_id, test_ctx.dataflow_id, payload)

                expect(err).to_be_nil()
                expect(commit).not_to_be_nil()
                expect(commit.commit_id).to_equal(commit_id)
                expect(commit.dataflow_id).to_equal(test_ctx.dataflow_id)
                expect(commit.payload.command).to_equal("test_command")
                expect(commit.created_at).not_to_be_nil()

                -- Verify in database
                local db, _ = sql.get("app:db")
                local rows, _ = db:query("SELECT * FROM dataflow_commits WHERE commit_id = ?", {commit_id})
                db:release()

                expect(#rows).to_equal(1)

                -- Check dataflow last_commit_id was updated
                db, _ = sql.get("app:db")
                local dataflow_rows, _ = db:query(
                    "SELECT last_commit_id FROM dataflows WHERE dataflow_id = ?",
                    {test_ctx.dataflow_id}
                )
                db:release()

                expect(dataflow_rows[1].last_commit_id).to_equal(commit_id)
            end)

            it("should create a commit with metadata", function()
                local commit_id = uuid.v7()
                local payload = { command = "metadata_command" }
                local metadata = {
                    source = "test",
                    node_id = uuid.v7() -- We can include any data in metadata
                }

                local commit, err = commit_repo.create(
                    commit_id,
                    test_ctx.dataflow_id,
                    payload,
                    metadata
                )

                expect(err).to_be_nil()
                expect(commit).not_to_be_nil()
                expect(commit.metadata.source).to_equal("test")
                expect(commit.metadata.node_id).not_to_be_nil()

                -- Verify metadata in database
                local db, _ = sql.get("app:db")
                local rows, _ = db:query("SELECT metadata FROM dataflow_commits WHERE commit_id = ?", {commit_id})
                db:release()

                local parsed_metadata = json.decode(rows[1].metadata)
                expect(parsed_metadata.source).to_equal("test")
                expect(parsed_metadata.node_id).to_equal(metadata.node_id)
            end)

            it("should create a commit with complex payload", function()
                local commit_id = uuid.v7()
                local payload = {
                    commands = {
                        { type = "CREATE_NODE", payload = { node_type = "test" } },
                        { type = "UPDATE_NODE", payload = { status = "running" } }
                    },
                    count = 2
                }

                local commit, err = commit_repo.create(
                    commit_id,
                    test_ctx.dataflow_id,
                    payload
                )

                expect(err).to_be_nil()
                expect(commit).not_to_be_nil()
                expect(commit.commit_id).to_equal(commit_id)
                expect(#commit.payload.commands).to_equal(2)
                expect(commit.payload.count).to_equal(2)
            end)

            it("should fail to create a commit without required fields", function()
                -- Without commit ID
                local _, err1 = commit_repo.create(
                    nil,
                    test_ctx.dataflow_id,
                    { test = true }
                )
                expect(err1).to_contain("Commit ID is required")

                -- Without dataflow ID
                local _, err2 = commit_repo.create(
                    uuid.v7(),
                    nil,
                    { test = true }
                )
                expect(err2).to_contain("Dataflow ID is required")

                -- Without payload
                local _, err3 = commit_repo.create(
                    uuid.v7(),
                    test_ctx.dataflow_id,
                    nil
                )
                expect(err3).to_contain("Payload is required")
            end)
        end)

        describe("Read operations", function()
            local test_commit_id

            before_all(function()
                -- Create a commit to retrieve later
                test_commit_id = uuid.v7()
                local payload = {
                    test_value = "retrievable",
                    nested = { key = "value" }
                }
                local metadata = { purpose = "retrieval_test" }

                local _, err = commit_repo.create(
                    test_commit_id,
                    test_ctx.dataflow_id,
                    payload,
                    metadata
                )

                if err then
                    error("Failed to create test commit: " .. err)
                end
            end)

            it("should get a commit by ID", function()
                local commit, err = commit_repo.get(test_commit_id)

                expect(err).to_be_nil()
                expect(commit).not_to_be_nil()
                expect(commit.commit_id).to_equal(test_commit_id)
                expect(commit.payload.test_value).to_equal("retrievable")
                expect(commit.payload.nested.key).to_equal("value")
                expect(commit.metadata.purpose).to_equal("retrieval_test")
            end)

            it("should return error for non-existent commit ID", function()
                local _, err = commit_repo.get(uuid.v7())
                expect(err).to_contain("Commit not found")
            end)

            it("should list commits for a dataflow", function()
                -- Create a few additional commits for this test
                local commit_ids = {}
                for i = 1, 3 do
                    local cid = uuid.v7()
                    table.insert(commit_ids, cid)
                    commit_repo.create(
                        cid,
                        test_ctx.dataflow_id,
                        { index = i, test_list = true }
                    )
                end

                -- Get all commits
                local commits, err = commit_repo.list_by_dataflow(test_ctx.dataflow_id)

                expect(err).to_be_nil()
                expect(commits).not_to_be_nil()
                -- Previous + 3 new = at least 4
                expect(#commits >= 4).to_be_true()

                -- Verify the commits are ordered by ID (timestamp order for UUID v7)
                for i = 2, #commits do
                    expect(commits[i].commit_id > commits[i-1].commit_id).to_be_true()
                end

                -- Verify limited result
                local limited_commits, err_limit = commit_repo.list_by_dataflow(
                    test_ctx.dataflow_id,
                    { limit = 2 }
                )
                expect(err_limit).to_be_nil()
                expect(#limited_commits).to_equal(2)
            end)

            it("should list all commits with list_after(nil)", function()
                -- Get all commits using list_after with nil
                local all_commits, err = commit_repo.list_after(test_ctx.dataflow_id, nil)

                expect(err).to_be_nil()
                expect(all_commits).not_to_be_nil()

                -- Compare with direct list_by_dataflow (should be equivalent)
                local direct_commits, _ = commit_repo.list_by_dataflow(test_ctx.dataflow_id)
                expect(#all_commits).to_equal(#direct_commits)
            end)

            it("should list commits after a specific ID", function()
                -- Get all commits
                local all_commits, _ = commit_repo.list_by_dataflow(test_ctx.dataflow_id)

                -- Choose a midpoint commit
                local mid_index = math.floor(#all_commits / 2)
                local mid_commit_id = all_commits[mid_index].commit_id

                -- Get commits after this ID
                local later_commits, err = commit_repo.list_after(
                    test_ctx.dataflow_id,
                    mid_commit_id
                )

                expect(err).to_be_nil()
                expect(later_commits).not_to_be_nil()
                expect(#later_commits).to_equal(#all_commits - mid_index)

                -- Verify all retrieved commits have IDs greater than the midpoint
                for _, commit in ipairs(later_commits) do
                    expect(commit.commit_id > mid_commit_id).to_be_true()
                end
            end)
        end)
    end)
end

return test.run_cases(define_tests)