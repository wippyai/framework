-- Fixture migration with an array meta.alias; bodies are idempotent because
-- the bootloader auto-applies it on test app boot and tests reset the ledger.
return require("migration").define(function()
    migration("Create alias_two table", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute("CREATE TABLE IF NOT EXISTS alias_two (id INTEGER PRIMARY KEY)")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local _, err = db:execute("DROP TABLE IF EXISTS alias_two")
                if err then
                    error(err)
                end
            end)
        end)
    end)
end)
