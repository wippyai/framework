local sql = require("sql")
local test = require("test")
local time = require("time")
local funcs = require("funcs")
local security = require("security")
local registry = require("registry")
local token_usage_repo = require("token_usage_repo")
local retention_policy = require("retention_policy")

local DAY = 86400
local DAY_MS = 86400000
local OWNER = "wippy.usage:retention"

local function open_db()
    local entry = registry.get("wippy.usage:target_db")
    local db, err = sql.get(tostring(entry.data.default))
    if err then error(err) end
    return db
end

local function stamp(unix_seconds)
    return time.unix(unix_seconds, 0):utc():format(time.RFC3339)
end

-- Removes every record older than a week so each case owns all prunable rows.
local function clear_old_records()
    local db = open_db()
    local cutoff = stamp(os.time() - 7 * DAY)
    local _, err = db:execute("DELETE FROM token_usage_cache_writes WHERE usage_id IN "
        .. "(SELECT usage_id FROM token_usage WHERE timestamp < $1)", { cutoff })
    if not err then
        _, err = db:execute("DELETE FROM token_usage WHERE timestamp < $1", { cutoff })
    end
    db:release()
    if err then error(err) end
end

local function record_at(unix_seconds, cache_write_by_ttl)
    local record, err = token_usage_repo.create("retention-user", "retention-model", 10, 5, {
        timestamp = unix_seconds,
        cache_write_tokens = cache_write_by_ttl and 30 or 0,
        cache_write_by_ttl = cache_write_by_ttl,
    })
    if err then error(err) end
    return record.usage_id
end

local function count(table_name, usage_id)
    local db = open_db()
    local rows, err = db:query("SELECT COUNT(*) AS n FROM " .. table_name .. " WHERE usage_id = $1", { usage_id })
    db:release()
    if err then error(err) end
    return tonumber(rows[1].n)
end

local function define_tests()
    describe("Token usage retention policy", function()
        it("defaults to 90 days in batches of 500", function()
            local policy, err = retention_policy.policy()
            test.is_nil(err)
            test.eq(policy.token_usage_ms, 90 * DAY_MS)
            test.eq(policy.batch_token_usage, 500)
        end)

        it("honours a declared override", function()
            local policy, err = retention_policy.resolve({
                retention = { token_usage = "30d", batch_token_usage = 20 },
            })
            test.is_nil(err)
            test.eq(policy.token_usage_ms, 30 * DAY_MS)
            test.eq(policy.batch_token_usage, 20)
        end)

        it("rejects an invalid policy", function()
            local invalid = {
                {},
                { retention = "90d" },
                { retention = { batch_token_usage = 500 } },
                { retention = { token_usage = "90", batch_token_usage = 500 } },
                { retention = { token_usage = 90, batch_token_usage = 500 } },
                { retention = { token_usage = "0d", batch_token_usage = 500 } },
                { retention = { token_usage = "3651d", batch_token_usage = 500 } },
                { retention = { token_usage = "90d" } },
                { retention = { token_usage = "90d", batch_token_usage = 0 } },
                { retention = { token_usage = "90d", batch_token_usage = 501 } },
                { retention = { token_usage = "90d", batch_token_usage = 2.5 } },
                { retention = { token_usage = "90d", batch_token_usage = "500" } },
            }
            for _, meta in ipairs(invalid) do
                local policy, err = retention_policy.resolve(meta)
                test.is_nil(policy)
                test.not_nil(err)
                test.eq(err:kind(), errors.INVALID)
                test.eq(err:retryable(), false)
            end
            local policy, err = retention_policy.resolve(nil)
            test.is_nil(policy)
            test.eq(err:kind(), errors.INVALID)
        end)
    end)

    describe("Token usage pruning", function()
        local base = 978307200 -- 2001-01-01T00:00:00Z

        before_each(clear_old_records)
        after_all(clear_old_records)

        it("deletes records stamped at or before the cutoff and keeps newer ones", function()
            local older = record_at(base - DAY)
            local at_cutoff = record_at(base)
            local newer = record_at(base + 1)

            local progress, err = token_usage_repo.prune(base, 10)
            test.is_nil(err)
            test.eq(progress.deleted, 2)
            test.eq(progress.needs_continue, false)
            test.eq(count("token_usage", older), 0)
            test.eq(count("token_usage", at_cutoff), 0)
            test.eq(count("token_usage", newer), 1)
        end)

        it("orders historical SQLite timestamps by instant across the cutoff", function()
            local db = open_db()
            local sqlite = tostring(db:type()) == "sqlite"
            db:release()
            if not sqlite then return end

            local older = record_at(base - 60, { ["5m"] = 10 })
            local newer = record_at(base + 60, { ["5m"] = 20 })
            local boundary = record_at(base)
            db = open_db()
            local _, older_err = db:execute("UPDATE token_usage SET timestamp = $1 WHERE usage_id = $2",
                { "2001-01-01T08:59:00+09:00", older })
            local _, newer_err = db:execute("UPDATE token_usage SET timestamp = $1 WHERE usage_id = $2",
                { "2000-12-31T19:01:00-05:00", newer })
            db:release()
            test.is_nil(older_err)
            test.is_nil(newer_err)

            local summary, summary_err = token_usage_repo.get_summary(base - 60, base)
            test.is_nil(summary_err)
            test.eq(summary.request_count, 2)
            test.eq(summary.cache_write_by_ttl["5m"], 10)

            local progress, err = token_usage_repo.prune(base, 1)
            test.is_nil(err)
            test.eq(progress.deleted, 1)
            test.eq(progress.needs_continue, true)
            test.eq(progress.oldest, base)
            test.eq(count("token_usage", older), 0)
            test.eq(count("token_usage_cache_writes", older), 0)
            test.eq(count("token_usage", boundary), 1)

            progress, err = token_usage_repo.prune(base, 1)
            test.is_nil(err)
            test.eq(progress.deleted, 1)
            test.eq(progress.needs_continue, false)
            test.eq(progress.oldest, base + 60)
            test.eq(count("token_usage", newer), 1)
            test.eq(count("token_usage_cache_writes", newer), 1)
        end)

        it("deletes the cache writes of pruned records", function()
            local pruned = record_at(base - DAY, { ["5m"] = 10, ["1h"] = 20 })
            local kept = record_at(base + DAY, { ["5m"] = 10, ["1h"] = 20 })
            test.eq(count("token_usage_cache_writes", pruned), 2)

            local progress, err = token_usage_repo.prune(base, 10)
            test.is_nil(err)
            test.eq(progress.deleted, 1)
            test.eq(count("token_usage_cache_writes", pruned), 0)
            test.eq(count("token_usage_cache_writes", kept), 2)
        end)

        it("deletes at most one batch, oldest first, and reports remaining work", function()
            local first = record_at(base - 3 * DAY)
            local second = record_at(base - 2 * DAY)
            local third = record_at(base - DAY)

            local progress, err = token_usage_repo.prune(base, 2)
            test.is_nil(err)
            test.eq(progress.deleted, 2)
            test.eq(progress.needs_continue, true)
            test.eq(count("token_usage", first), 0)
            test.eq(count("token_usage", second), 0)
            test.eq(count("token_usage", third), 1)

            progress, err = token_usage_repo.prune(base, 2)
            test.is_nil(err)
            test.eq(progress.deleted, 1)
            test.eq(progress.needs_continue, false)
            test.eq(count("token_usage", third), 0)
        end)

        it("reports the timestamp of the oldest remaining record", function()
            record_at(base - DAY)
            record_at(base + 2 * DAY)
            record_at(base + 3 * DAY)

            local progress, err = token_usage_repo.prune(base, 10)
            test.is_nil(err)
            test.eq(progress.oldest, base + 2 * DAY)
        end)

        it("rejects an invalid cutoff or batch size", function()
            for _, args in ipairs({ { nil, 10 }, { "2001-01-01", 10 }, { base, 0 }, { base, 501 }, { base, 1.5 } }) do
                local progress, err = token_usage_repo.prune(args[1], args[2])
                test.is_nil(progress)
                test.not_nil(err)
            end
        end)
    end)

    describe("Token usage retention owner", function()
        before_each(clear_old_records)
        after_all(clear_old_records)

        it("prunes records past the default policy and returns the owner protocol", function()
            local now = os.time()
            local expired = record_at(now - 91 * DAY, { ["5m"] = 10 })
            local retained_at = now - 89 * DAY
            local retained = record_at(retained_at, { ["5m"] = 10 })

            local result, err = funcs.call(OWNER, {})
            test.is_nil(err)
            test.eq(result.success, true)
            test.eq(result.deleted, 1)
            test.eq(result.needs_continue, false)
            test.eq(result.deadline_ms, retained_at * 1000 + 90 * DAY_MS)
            test.is_nil(result.error)
            test.eq(count("token_usage", expired), 0)
            test.eq(count("token_usage_cache_writes", expired), 0)
            test.eq(count("token_usage", retained), 1)
            test.eq(count("token_usage_cache_writes", retained), 1)
        end)

        it("runs with its declared security under a caller scope without grants", function()
            local now = os.time()
            local expired = record_at(now - 91 * DAY)

            local executor = funcs.new()
            local bound, bind_err = executor:with_scope(security.new_scope({}))
            test.is_nil(bind_err)
            local result, err = bound:call(OWNER, {})
            test.is_nil(err)
            test.eq(result.success, true)
            test.eq(result.deleted, 1)
            test.eq(count("token_usage", expired), 0)
        end)
    end)
end

return test.run_cases(define_tests)
