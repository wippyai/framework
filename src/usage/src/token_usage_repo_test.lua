local sql = require("sql")
local test = require("test")
local uuid = require("uuid")
local json = require("json")
local token_usage_repo = require("token_usage_repo")
local time = require("time")
local env = require("env")

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
            local db_resource, _ = env.get("wippy.usage.env:target_db")
            local db, err = sql.get(db_resource)
            if err then
                error("Failed to connect to database: " .. err)
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

            expect(err).to_be_nil()
            expect(record).not_to_be_nil()
            expect(record.user_id).to_equal(test_data.user_id)
            expect(record.context_id).to_equal(test_data.context_id)
            expect(record.model_id).to_equal(test_data.model_id)
            expect(record.prompt_tokens).to_equal(100)
            expect(record.completion_tokens).to_equal(50)
            expect(record.timestamp).not_to_be_nil()

            -- Store the new record for cleanup
            if record then
                table.insert(created_records, record.usage_id)
            end
        end)

        it("should get usage summary", function()
            local start_time = test_data.base_time - 7200 -- 2 hours ago
            local end_time = test_data.base_time + 3600   -- 1 hour from now

            -- Query only for our test users to isolate the data
            local db_resource, _ = env.get("wippy.usage.env:target_db")
            local db, db_err = sql.get(db_resource)
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

            expect(err).to_be_nil()
            expect(summary).not_to_be_nil()

            -- Check that the overall count in our database contains at least our records
            expect(summary.total_prompt_tokens >= 450).to_be_true()
            expect(summary.total_completion_tokens >= 225).to_be_true()
            expect(summary.total_tokens >= 675).to_be_true()
        end)

        it("should get usage by time with daily interval", function()
            local start_time = test_data.base_time - 86400 -- 1 day ago
            local end_time = test_data.base_time + 3600   -- 1 hour from now

            local time_usage, err = token_usage_repo.get_usage_by_time(start_time, end_time, token_usage_repo.INTERVAL.DAY)

            expect(err).to_be_nil()
            expect(time_usage).not_to_be_nil()

            -- We know our test data is all in a short time period, so there should be at least one entry
            expect(#time_usage >= 1).to_be_true()
        end)

        it("should get usage by model", function()
            local start_time = test_data.base_time - 7200 -- 2 hours ago
            local end_time = test_data.base_time + 3600   -- 1 hour from now

            local model_usage, err = token_usage_repo.get_usage_by_model(start_time, end_time)

            expect(err).to_be_nil()
            expect(model_usage).not_to_be_nil()

            -- There should be at least our two test models
            local found_test_models = 0
            for _, model in ipairs(model_usage) do
                if model.model_id == test_data.model_id or model.model_id == test_data.model_id2 then
                    found_test_models = found_test_models + 1
                end
            end
            expect(found_test_models >= 2).to_be_true()
        end)

        it("should handle validation errors", function()
            -- Missing user_id
            local record, err = token_usage_repo.create(nil, test_data.model_id, 100, 50)
            expect(record).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("User ID is required")).not_to_be_nil()

            -- Missing model_id
            record, err = token_usage_repo.create(test_data.user_id, "", 100, 50)
            expect(record).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("Model ID is required")).not_to_be_nil()

            -- Invalid prompt_tokens
            record, err = token_usage_repo.create(test_data.user_id, test_data.model_id, "100", 50)
            expect(record).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("Prompt tokens must be a number")).not_to_be_nil()

            -- Invalid completion_tokens
            record, err = token_usage_repo.create(test_data.user_id, test_data.model_id, 100, "50")
            expect(record).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("Completion tokens must be a number")).not_to_be_nil()
        end)
    end)
end

return test.run_cases(define_tests)
