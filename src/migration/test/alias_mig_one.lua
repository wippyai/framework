-- Fixture migration with a string meta.alias; bodies are idempotent because
-- the bootloader auto-applies it on test app boot and tests reset the ledger.
return require("migration").define(function()
    migration("Create alias_one table", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute("CREATE TABLE IF NOT EXISTS alias_one (id INTEGER PRIMARY KEY)")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local _, err = db:execute("DROP TABLE IF EXISTS alias_one")
                if err then
                    error(err)
                end
            end)
        end)
    end)
end)
