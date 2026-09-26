return require("migration").define(function()
    migration("Fixture table for the single-step ledger hash test", function()
        database("sqlite", function()
            up(function(db)
                local _, err = db:execute("CREATE TABLE ledger_hash_fixture (id TEXT PRIMARY KEY)")
                if err then error(err) end
            end)
            down(function(db)
                local _, err = db:execute("DROP TABLE IF EXISTS ledger_hash_fixture")
                if err then error(err) end
            end)
        end)
        database("postgres", function()
            up(function(db)
                local _, err = db:execute("CREATE TABLE ledger_hash_fixture (id TEXT PRIMARY KEY)")
                if err then error(err) end
            end)
            down(function(db)
                local _, err = db:execute("DROP TABLE IF EXISTS ledger_hash_fixture")
                if err then error(err) end
            end)
        end)
    end)
end)
