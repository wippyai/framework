local migration_api = require("migration_api")
local time = require("time")

local function apply(i: number, options)
    local table_name = "concurrency_probe_" .. tostring(i)
    return migration_api.run(function()
        migration("Concurrent migration " .. tostring(i), function()
            for _, db_type in ipairs({"postgres", "sqlite"}) do
                database(db_type, function()
                    up(function(tx)
                        -- Hold the transaction while the competing runner arrives.
                        time.sleep("150ms")
                        local ok, err = tx:execute("CREATE TABLE " .. table_name .. " (value INTEGER)")
                        if not ok then error(tostring(err)) end
                        ok, err = tx:execute("INSERT INTO " .. table_name .. " VALUES (1)")
                        if not ok then error(tostring(err)) end
                    end)
                    after(function(tx)
                        local ok, err = tx:execute("INSERT INTO " .. table_name .. " VALUES (2)")
                        if not ok then error(tostring(err)) end
                    end)
                end)
            end
        end)
    end, options)
end

return {
    first = function(options) return apply(1, options) end,
    second = function(options) return apply(2, options) end,
    third = function(options) return apply(3, options) end,
}
