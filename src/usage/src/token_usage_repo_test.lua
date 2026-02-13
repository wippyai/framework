local sql = require("sql")
local test = require("test")
local uuid = require("uuid")
local json = require("json")
local token_usage_repo = require("token_usage_repo")
local time = require("time")
local registry = require("registry")

local function define_tests()
    describe("Token Usage Repository", function()
        -- Test data with unique identifiers
        local test_data = {
            user_id = "test-user-" .. uuid.v7(),
            user_id2 = "test-user-" .. uuid.v7(),
            context_id = "test-context-" .. uuid.v7(),
            model_id = "test-model-gpt-4-turbo",
            model_id2 = "test-model-claude-3-opus",
            base_time = os.time()
        }

        local created_records = {}

        -- Setup test data before tests
        before_all(function()
            -- Create test usage records for different times, users, and models
            local record, err = token_usage_repo.create(
                test_data.user_id,
                test_data.model_id,
                100,  -- prompt_tokens
                50,   -- completion_tokens
                {
                    context_id = test_data.context_id,
                    timestamp = test_data.base_time - 3600, -- 1 hour ago
                    meta = { request_type = "chat" }
                }
            )
            if record then
                table.insert(created_records, record.usage_id)
            end

            record, err = token_usage_repo.create(
                test_data.user_id,
                test_data.model_id2,
                200,  -- prompt_tokens
                100,  -- completion_tokens
                {
                    context_id = test_data.context_id,
                    timestamp = test_data.base_time - 1800, -- 30 minutes ago
                    meta = { request_type = "completion" }
                }
            )
            if record then
                table.insert(created_records, record.usage_id)
            end

            record, err = token_usage_repo.create(
                test_data.user_id2,
                test_data.model_id,
                150,  -- prompt_tokens
                75,   -- completion_tokens
                {
                    timestamp = test_data.base_time - 900, -- 15 minutes ago
                    meta = { request_type = "query" }
                }
            )
            if record then
                table.insert(created_records, record.usage_id)
            end
        end)

        -- Clean up test data after all tests
        after_all(function()
            -- Get a database connection for cleanup
            local entry, _ = registry.get("wippy.usage:target_db")
            local db_resource = entry.data.default
            local db, err = sql.get(tostring(db_resource))
            if err then
                error("Failed to connect to database: " .. tostring(err))
            end

            -- Only delete our specific test records by using the collected usage_ids
            for _, usage_id in ipairs(created_records) do
                db:execute("DELETE FROM token_usage WHERE usage_id = $1", {usage_id})
            end

            db:release()
        end)

        it("should create a token usage record", function()
            local record, err = token_usage_repo.create(
                test_data.user_id,
                test_data.model_id,
                100,  -- prompt_tokens
                50,   -- completion_tokens
                {
                    context_id = test_data.context_id,
                    meta = {
                        request_type = "chat",
                        tags = {"test", "initial"}
                    }
                }
            )

            test.is_nil(err)
            test.not_nil(record)
            test.eq(record.user_id, test_data.user_id)
            test.eq(record.context_id, test_data.context_id)
            test.eq(record.model_id, test_data.model_id)
            test.eq(record.prompt_tokens, 100)
            test.eq(record.completion_tokens, 50)
            test.not_nil(record.timestamp)

            -- Store the new record for cleanup
            if record then
                table.insert(created_records, record.usage_id)
            end
        end)

        it("should get usage summary", function()
            local start_time = test_data.base_time - 7200 -- 2 hours ago
            local end_time = test_data.base_time + 3600   -- 1 hour from now

            -- Query only for our test users to isolate the data
            local entry, _ = registry.get("wippy.usage:target_db")
            local db_resource = entry.data.default
            local db, db_err = sql.get(tostring(db_resource))
            if db_err then error(db_err) end

            -- First check what records we actually have in our time range
            local results, check_err = db:query(
                "SELECT SUM(prompt_tokens) as total_prompt FROM token_usage WHERE " ..
                "user_id IN ($1, $2) AND timestamp >= $3 AND timestamp <= $4",
                {test_data.user_id, test_data.user_id2,
                time.unix(start_time, 0):format(time.RFC3339),
                time.unix(end_time, 0):format(time.RFC3339)}
            )

            if check_err then error(check_err) end

            local expected_total = (results and results[1] and results[1].total_prompt) or 0
            db:release()

            local summary, err = token_usage_repo.get_summary(start_time, end_time)

            test.is_nil(err)
            test.not_nil(summary)

            -- Check that the overall count in our database contains at least our records
            test.is_true(summary.total_prompt_tokens >= 450)
            test.is_true(summary.total_completion_tokens >= 225)
            test.is_true(summary.total_tokens >= 675)
        end)

        it("should get usage by time with daily interval", function()
            local start_time = test_data.base_time - 86400 -- 1 day ago
            local end_time = test_data.base_time + 3600   -- 1 hour from now

            local time_usage, err = token_usage_repo.get_usage_by_time(start_time, end_time, token_usage_repo.INTERVAL.DAY)

            test.is_nil(err)
            test.not_nil(time_usage)

            -- We know our test data is all in a short time period, so there should be at least one entry
            test.is_true(#time_usage >= 1)
        end)

        it("should get usage by model", function()
            local start_time = test_data.base_time - 7200 -- 2 hours ago
            local end_time = test_data.base_time + 3600   -- 1 hour from now

            local model_usage, err = token_usage_repo.get_usage_by_model(start_time, end_time)

            test.is_nil(err)
            test.not_nil(model_usage)

            -- There should be at least our two test models
            local found_test_models = 0
            for _, model in ipairs(model_usage) do
                if model.model_id == test_data.model_id or model.model_id == test_data.model_id2 then
                    found_test_models = found_test_models + 1
                end
            end
            test.is_true(found_test_models >= 2)
        end)

        it("should handle validation errors", function()
            -- Missing user_id
            local record, err = token_usage_repo.create(nil, test_data.model_id, 100, 50)
            test.is_nil(record)
            test.not_nil(err)
            test.not_nil(err:match("User ID is required"))

            -- Missing model_id
            record, err = token_usage_repo.create(test_data.user_id, "", 100, 50)
            test.is_nil(record)
            test.not_nil(err)
            test.not_nil(err:match("Model ID is required"))

            -- Invalid prompt_tokens
            record, err = token_usage_repo.create(test_data.user_id, test_data.model_id, "100", 50)
            test.is_nil(record)
            test.not_nil(err)
            test.not_nil(err:match("Prompt tokens must be a number"))

            -- Invalid completion_tokens
            record, err = token_usage_repo.create(test_data.user_id, test_data.model_id, 100, "50")
            test.is_nil(record)
            test.not_nil(err)
            test.not_nil(err:match("Completion tokens must be a number"))
        end)
    end)
end

return test.run_cases(define_tests)
