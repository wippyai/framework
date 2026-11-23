local function replace_index(db, new_index, old_index)
    local _, err = db:execute(new_index)
    if err then error(err) end
    _, err = db:execute(old_index)
    if err then error(err) end
end

return require("migration").define(function()
    migration("Index token usage timestamps by instant", function()
        database("sqlite", function()
            up(function(db)
                replace_index(db,
                    "CREATE INDEX idx_token_usage_timestamp_epoch ON token_usage(CAST(strftime('%s', timestamp) AS INTEGER))",
                    "DROP INDEX idx_token_usage_timestamp")
            end)

            down(function(db)
                replace_index(db,
                    "CREATE INDEX idx_token_usage_timestamp ON token_usage(timestamp)",
                    "DROP INDEX idx_token_usage_timestamp_epoch")
            end)
        end)

        database("postgres", function()
            up(function()
                -- PostgreSQL's timestamp index already orders stored instants.
            end)

            down(function()
            end)
        end)
    end)
end)
