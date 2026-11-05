return require("migration").define(function()
    migration("Create token_usage_cache_writes table", function()
        database("postgres", function()
            up(function(db)
                local _, err = db:execute([[
                    CREATE TABLE token_usage_cache_writes (
                        usage_id TEXT NOT NULL REFERENCES token_usage(usage_id) ON DELETE CASCADE,
                        ttl TEXT NOT NULL,
                        tokens INTEGER NOT NULL,
                        PRIMARY KEY (usage_id, ttl)
                    )
                ]])
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local _, err = db:execute("DROP TABLE IF EXISTS token_usage_cache_writes")
                if err then
                    error(err)
                end
            end)
        end)

        database("sqlite", function()
            up(function(db)
                local _, err = db:execute([[
                    CREATE TABLE token_usage_cache_writes (
                        usage_id TEXT NOT NULL REFERENCES token_usage(usage_id) ON DELETE CASCADE,
                        ttl TEXT NOT NULL,
                        tokens INTEGER NOT NULL,
                        PRIMARY KEY (usage_id, ttl)
                    )
                ]])
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local _, err = db:execute("DROP TABLE IF EXISTS token_usage_cache_writes")
                if err then
                    error(err)
                end
            end)
        end)
    end)
end)
