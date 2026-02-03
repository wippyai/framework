local test = require("test")
local sql = require("sql")
local uuid = require("uuid")
local env = require("env")
local embedding_repo = require("embedding_repo")

local function define_tests()
    test.describe("Embedding Repository", function()
        local origin_id_1 = uuid.v4()
        local origin_id_2 = uuid.v4()
        local context_id_1 = "test_context_a"
        local context_id_2 = "test_context_b"

        local embedding_1 = {}
        local embedding_2 = {}
        local embedding_3 = {}
        local embedding_4 = {}
        local embedding_5 = {}

        for i = 1, 512 do
            embedding_1[i] = math.random() - 0.5
            embedding_2[i] = math.random() - 0.5
            embedding_3[i] = math.random() - 0.5
            embedding_4[i] = math.random() - 0.5
            embedding_5[i] = math.random() - 0.5
        end

        test.after_all(function()
            local db_resource = env.get("wippy.embeddings.env:target_db")
            local db, err = sql.get(db_resource)
            if err then
                print("Warning: Could not connect to database for cleanup: " .. err)
                return
            end

            local query = sql.builder.delete("embeddings_512")
                :where("content_type LIKE ?", "filter_test%")

            local executor = query:run_with(db)
            local result, del_err = executor:exec()

            if del_err then
                print("Warning: Could not clean up test embeddings: " .. del_err)
            else
                print("Cleaned up " .. result.rows_affected .. " test embeddings")
            end

            db:release()
        end)

        test.it("should add a single embedding", function()
            local result, err = embedding_repo.add(
                "Document about machine learning algorithms for text classification.",
                "filter_test_document",
                origin_id_1,
                context_id_1,
                { category = "ml", importance = "high" },
                embedding_1
            )

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.entry_id)
            test.eq(result.origin_id, origin_id_1)
            test.eq(result.content_type, "filter_test_document")
            test.eq(result.context_id, context_id_1)
        end)

        test.it("should add multiple embeddings in a batch", function()
            local batch = {
                {
                    content = "Query about natural language processing techniques.",
                    content_type = "filter_test_query",
                    origin_id = origin_id_1,
                    context_id = context_id_1,
                    meta = { category = "nlp", importance = "medium" },
                    embedding = embedding_2
                },
                {
                    content = "Document about deep learning for image recognition.",
                    content_type = "filter_test_document",
                    origin_id = origin_id_1,
                    context_id = context_id_2,
                    meta = { category = "ml", importance = "high" },
                    embedding = embedding_3
                },
                {
                    content = "Document about database optimization techniques.",
                    content_type = "filter_test_document",
                    origin_id = origin_id_2,
                    context_id = context_id_1,
                    meta = { category = "db", importance = "high" },
                    embedding = embedding_4
                },
                {
                    content = "Query about SQL performance benchmarks.",
                    content_type = "filter_test_query",
                    origin_id = origin_id_2,
                    context_id = context_id_2,
                    meta = { category = "db", importance = "low" },
                    embedding = embedding_5
                }
            }

            local result, err = embedding_repo.add_batch(batch)

            test.is_nil(err)
            test.not_nil(result)
            test.eq(result.count, #batch)
            test.eq(#result.items, #batch)

            for _, item in ipairs(result.items) do
                test.not_nil(item.entry_id)
            end
        end)

        test.it("should get embeddings by origin_id", function()
            local results, err = embedding_repo.get_by_origin(origin_id_1)

            test.is_nil(err)
            test.not_nil(results)
            test.eq(#results, 3)

            for _, result in ipairs(results) do
                test.eq(result.origin_id, origin_id_1)
            end
        end)

        test.it("should filter search results by origin_id", function()
            local query_embedding = embedding_1

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                origin_id = origin_id_1
            })

            test.is_nil(err)
            test.not_nil(results)

            for _, result in ipairs(results) do
                test.eq(result.origin_id, origin_id_1)
            end

            results, err = embedding_repo.search_by_embedding(query_embedding, {
                origin_id = origin_id_2
            })

            test.is_nil(err)
            test.not_nil(results)

            for _, result in ipairs(results) do
                test.eq(result.origin_id, origin_id_2)
            end
        end)

        test.it("should filter search results by content_type", function()
            local query_embedding = embedding_1

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                content_type = "filter_test_document"
            })

            test.is_nil(err)
            test.not_nil(results)

            for _, result in ipairs(results) do
                test.eq(result.content_type, "filter_test_document")
            end

            results, err = embedding_repo.search_by_embedding(query_embedding, {
                content_type = "filter_test_query"
            })

            test.is_nil(err)
            test.not_nil(results)

            for _, result in ipairs(results) do
                test.eq(result.content_type, "filter_test_query")
            end
        end)

        test.it("should filter search results by context_id", function()
            local query_embedding = embedding_1

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                context_id = context_id_1
            })

            test.is_nil(err)
            test.not_nil(results)

            for _, result in ipairs(results) do
                test.eq(result.context_id, context_id_1)
            end

            results, err = embedding_repo.search_by_embedding(query_embedding, {
                context_id = context_id_2
            })

            test.is_nil(err)
            test.not_nil(results)

            for _, result in ipairs(results) do
                test.eq(result.context_id, context_id_2)
            end
        end)

        test.it("should apply multiple filters correctly", function()
            local query_embedding = embedding_1

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                origin_id = origin_id_1,
                content_type = "filter_test_document"
            })

            test.is_nil(err)
            test.not_nil(results)

            for _, result in ipairs(results) do
                test.eq(result.origin_id, origin_id_1)
                test.eq(result.content_type, "filter_test_document")
            end

            results, err = embedding_repo.search_by_embedding(query_embedding, {
                origin_id = origin_id_2,
                content_type = "filter_test_query",
                context_id = context_id_2
            })

            test.is_nil(err)

            for _, result in ipairs(results) do
                test.eq(result.origin_id, origin_id_2)
                test.eq(result.content_type, "filter_test_query")
                test.eq(result.context_id, context_id_2)
            end
        end)

        test.it("should respect the limit parameter", function()
            local query_embedding = embedding_1
            local limit = 2

            local results, err = embedding_repo.search_by_embedding(query_embedding, {
                limit = limit
            })

            test.is_nil(err)
            test.not_nil(results)
            test.ok(#results <= limit)
        end)

        test.it("should delete an embedding by entry_id", function()
            local results, err = embedding_repo.get_by_origin(origin_id_1)
            test.is_nil(err)
            test.ok(#results > 0)

            local entry_id = results[1].entry_id

            local delete_result, del_err = embedding_repo.delete_by_entry(entry_id)
            test.is_nil(del_err)
            test.is_true(delete_result.deleted)

            local all_results, get_err = embedding_repo.get_by_origin(origin_id_1)
            test.is_nil(get_err)

            local found = false
            for _, result in ipairs(all_results) do
                if result.entry_id == entry_id then
                    found = true
                    break
                end
            end
            test.is_false(found)
        end)

        test.it("should delete all embeddings by origin_id", function()
            local delete_result, err = embedding_repo.delete_by_origin(origin_id_2)
            test.is_nil(err)
            test.is_true(delete_result.deleted)
            test.ok(delete_result.count > 0)

            local results, get_err = embedding_repo.get_by_origin(origin_id_2)
            test.is_nil(get_err)
            test.eq(#results, 0)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
