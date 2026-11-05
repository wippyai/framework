local sql = require("sql")
local test = require("test")
local uuid = require("uuid")
local registry = require("registry")
local usage_tracker = require("usage_tracker")

local function open_db()
    local entry, _ = registry.get("wippy.usage:target_db")
    local db, err = sql.get(tostring(entry.data.default))
    if err then error(err) end
    return db
end

local function define_tests()
    describe("Usage Tracker", function()
        local created = {}

        local function stored_cache_writes(usage_id)
            local db = open_db()
            local rows, err = db:query(
                "SELECT ttl, tokens FROM token_usage_cache_writes WHERE usage_id = $1 ORDER BY ttl",
                { usage_id }
            )
            db:release()
            if err then error(err) end
            return rows
        end

        after_all(function()
            local db = open_db()
            for _, usage_id in ipairs(created) do
                db:execute("DELETE FROM token_usage_cache_writes WHERE usage_id = $1", { usage_id })
                db:execute("DELETE FROM token_usage WHERE usage_id = $1", { usage_id })
            end
            db:release()
        end)

        it("records the cache write breakdown by lifetime", function()
            local usage_id, err = usage_tracker.track_usage("test-model-" .. uuid.v7(), 10, 5, 0, 40, 300, {
                cache_write_by_ttl = { ["5m"] = 100, ["1h"] = 200 }
            })

            test.is_nil(err)
            table.insert(created, usage_id)
            local rows = stored_cache_writes(usage_id)
            test.eq(#rows, 2)
            test.eq(rows[1].ttl, "1h")
            test.eq(rows[1].tokens, 200)
            test.eq(rows[2].ttl, "5m")
            test.eq(rows[2].tokens, 100)
        end)

        it("records no breakdown when the caller reports none", function()
            local usage_id, err = usage_tracker.track_usage("test-model-" .. uuid.v7(), 10, 5, 0, 0, 30, {})

            test.is_nil(err)
            table.insert(created, usage_id)
            test.eq(#stored_cache_writes(usage_id), 0)
        end)

        local function stored_cache_write_tokens(usage_id)
            local db = open_db()
            local rows, err = db:query("SELECT cache_write_tokens FROM token_usage WHERE usage_id = $1", { usage_id })
            db:release()
            if err then error(err) end
            return rows[1] and rows[1].cache_write_tokens
        end

        it("keeps the usage record without a breakdown larger than the cache writes", function()
            local usage_id, err = usage_tracker.track_usage("test-model-" .. uuid.v7(), 10, 5, 0, 0, 300, {
                cache_write_by_ttl = { ["1h"] = 250, ["5m"] = 100 }
            })

            test.is_nil(err)
            test.not_nil(usage_id)
            table.insert(created, usage_id)
            test.eq(stored_cache_write_tokens(usage_id), 300)
            test.eq(#stored_cache_writes(usage_id), 0)
        end)

        it("keeps the usage record without a malformed breakdown", function()
            local cases = {
                { breakdown = "1h" },
                { breakdown = { ["1h"] = -1 } },
                { breakdown = { ["1h"] = "200" } },
                { breakdown = { ["1h"] = 10.5 } },
                { breakdown = { 200 } },
                { breakdown = { [""] = 10 } },
            }
            for _, case in ipairs(cases) do
                local usage_id, err = usage_tracker.track_usage("test-model-" .. uuid.v7(), 10, 5, 0, 0, 300, {
                    cache_write_by_ttl = case.breakdown
                })

                test.is_nil(err)
                test.not_nil(usage_id)
                table.insert(created, usage_id)
                test.eq(stored_cache_write_tokens(usage_id), 300)
                test.eq(#stored_cache_writes(usage_id), 0)
            end
        end)
    end)
end

return test.run_cases(define_tests)
