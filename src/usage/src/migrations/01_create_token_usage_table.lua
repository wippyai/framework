-- 01_create_token_usage_table.lua (updated)
return require("migration").define(function()
    migration("Create token_usage table", function()
        database("postgres", function()
            up(function(db)
                -- Create token_usage table
                local success, err = db:execute([[
                    CREATE TABLE token_usage (
                        usage_id TEXT PRIMARY KEY,
                        user_id TEXT NOT NULL,
                        context_id TEXT,
                        model_id TEXT NOT NULL,
                        prompt_tokens INTEGER NOT NULL,
                        completion_tokens INTEGER NOT NULL,
                        thinking_tokens INTEGER NOT NULL DEFAULT 0,
                        cache_read_tokens INTEGER NOT NULL DEFAULT 0,
                        cache_write_tokens INTEGER NOT NULL DEFAULT 0,
                        timestamp timestamp NOT NULL DEFAULT now(),
                        meta TEXT
                    )
                ]])

                if err then
                    error(err)
                end

                -- Create indexes
                success, err = db:execute("CREATE INDEX idx_token_usage_user ON token_usage(user_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_token_usage_context ON token_usage(context_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_token_usage_model ON token_usage(model_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_token_usage_timestamp ON token_usage(timestamp)")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                -- Drop indexes first
                local success, err = db:execute("DROP INDEX IF EXISTS idx_token_usage_user")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_token_usage_context")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_token_usage_model")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_token_usage_timestamp")
                if err then
                    error(err)
                end

                -- Drop table
                success, err = db:execute("DROP TABLE IF EXISTS token_usage")
                if err then
                    error(err)
                end
            end)
        end)

        database("sqlite", function()
            up(function(db)
                -- Create token_usage table
                local success, err = db:execute([[
                    CREATE TABLE token_usage (
                        usage_id TEXT PRIMARY KEY,
                        user_id TEXT NOT NULL,
                        context_id TEXT,
                        model_id TEXT NOT NULL,
                        prompt_tokens INTEGER NOT NULL,
                        completion_tokens INTEGER NOT NULL,
                        thinking_tokens INTEGER NOT NULL DEFAULT 0,
                        cache_read_tokens INTEGER NOT NULL DEFAULT 0,
                        cache_write_tokens INTEGER NOT NULL DEFAULT 0,
                        timestamp INTEGER NOT NULL,
                        meta TEXT
                    )
                ]])

                if err then
                    error(err)
                end

                -- Create indexes
                success, err = db:execute("CREATE INDEX idx_token_usage_user ON token_usage(user_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_token_usage_context ON token_usage(context_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_token_usage_model ON token_usage(model_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_token_usage_timestamp ON token_usage(timestamp)")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                -- Drop indexes first
                local success, err = db:execute("DROP INDEX IF EXISTS idx_token_usage_user")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_token_usage_context")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_token_usage_model")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_token_usage_timestamp")
                if err then
                    error(err)
                end

                -- Drop table
                success, err = db:execute("DROP TABLE IF EXISTS token_usage")
                if err then
                    error(err)
                end
            end)
        end)
    end)
end)