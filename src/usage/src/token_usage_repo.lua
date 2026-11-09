local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local registry = require("registry")

local NS = "wippy.usage:"

local token_usage_repo = {}

token_usage_repo.INTERVAL = {
    HOUR = "hour",
    DAY = "day",
    WEEK = "week",
    MONTH = "month"
}

local function get_db()
    local entry, entry_err = registry.get(NS .. "target_db")
    if entry_err or not entry then
        return nil, "target_db requirement is not configured"
    end

    local db_resource = entry.data and entry.data.default
    if not db_resource or db_resource == "" then
        return nil, "target_db requirement value is empty"
    end

    local db, err = sql.get(tostring(db_resource))
    if err then
        return nil, "Failed to connect to database: " .. tostring(err)
    end
    return db
end

local function positive_cache_writes(by_ttl)
    local writes = {}
    if type(by_ttl) ~= "table" then
        return writes
    end
    for ttl, tokens in pairs(by_ttl) do
        if type(ttl) == "string" and type(tokens) == "number" and tokens > 0 then
            table.insert(writes, { ttl = ttl, tokens = tokens })
        end
    end
    table.sort(writes, function(a, b) return a.ttl < b.ttl end)
    return writes
end

local function insert_with_cache_writes(db, usage_query, usage_id, cache_writes)
    local tx, begin_err = db:begin()
    if begin_err then
        return begin_err
    end
    local _, err = usage_query:run_with(tx):exec()
    for _, write in ipairs(cache_writes) do
        if err then
            break
        end
        _, err = sql.builder.insert("token_usage_cache_writes")
            :set_map({ usage_id = usage_id, ttl = write.ttl, tokens = sql.as.int(write.tokens) })
            :run_with(tx)
            :exec()
    end
    if err then
        tx:rollback()
        return err
    end
    local _, commit_err = tx:commit()
    return commit_err
end

local function cache_writes_by(db, group_column, where_sql, params)
    local grouped = group_column ~= nil
    local query = "SELECT " .. (grouped and (group_column .. " AS grp, ") or "")
        .. "w.ttl AS ttl, SUM(w.tokens) AS tokens"
        .. " FROM token_usage_cache_writes w JOIN token_usage u ON u.usage_id = w.usage_id"
        .. " WHERE " .. where_sql
        .. " GROUP BY " .. (grouped and (group_column .. ", ") or "") .. "w.ttl"
    local rows, err = db:query(query, params)
    if err then
        return nil, err
    end
    local by_group = {}
    for _, row in ipairs(rows or {}) do
        local key = grouped and tostring(row.grp) or ""
        by_group[key] = by_group[key] or {}
        by_group[key][row.ttl] = row.tokens
    end
    return by_group
end

local function report_bounds(start_time, end_time)
    return { time.unix(start_time, 0):utc():format(time.RFC3339),
        time.unix(end_time, 0):utc():format(time.RFC3339) }
end

-- Create a new token usage record
function token_usage_repo.create(user_id, model_id, prompt_tokens, completion_tokens, options)
    if not user_id or user_id == "" then
        return nil, "User ID is required"
    end

    if not model_id or model_id == "" then
        return nil, "Model ID is required"
    end

    if not prompt_tokens or type(prompt_tokens) ~= "number" then
        return nil, "Prompt tokens must be a number"
    end

    if not completion_tokens or type(completion_tokens) ~= "number" then
        return nil, "Completion tokens must be a number"
    end

    -- Initialize options if not provided
    options = options or {}

    -- Convert meta to JSON if it's a table
    local meta_json = nil
    if options.metadata then
        if type(options.metadata) == "table" then
            local encoded, err = json.encode(options.metadata)
            if err then
                return nil, "Failed to encode meta: " .. tostring(err)
            end
            meta_json = encoded
        else
            meta_json = options.meta
        end
    end

    local db, err = get_db()
    if err then
        return nil, err
    end

    local now
    if options.timestamp == nil then
        now = time.now():utc():format(time.RFC3339)
    else
        now = time.unix(options.timestamp, 0):utc():format(time.RFC3339)
    end

    local usage_id = uuid.v7()

    -- Extract the new token types from options
    local thinking_tokens = options.thinking_tokens or 0
    local cache_read_tokens = options.cache_read_tokens or 0
    local cache_write_tokens = options.cache_write_tokens or 0
    local cache_writes = positive_cache_writes(options.cache_write_by_ttl)
    local stored_by_ttl = nil
    for _, write in ipairs(cache_writes) do
        stored_by_ttl = stored_by_ttl or {}
        stored_by_ttl[write.ttl] = write.tokens
    end

    -- Build the INSERT query
    local query = sql.builder.insert("token_usage")
        :set_map({
            usage_id = usage_id,
            user_id = user_id,
            context_id = options.context_id or sql.as.null(),
            model_id = model_id,
            prompt_tokens = sql.as.int(prompt_tokens),
            completion_tokens = sql.as.int(completion_tokens),
            thinking_tokens = sql.as.int(thinking_tokens),
            cache_read_tokens = sql.as.int(cache_read_tokens),
            cache_write_tokens = sql.as.int(cache_write_tokens),
            timestamp = now,
            meta = meta_json or sql.as.null()
        })

    -- Execute the query
    local insert_err
    if #cache_writes == 0 then
        local _, exec_err = query:run_with(db):exec()
        insert_err = exec_err
    else
        insert_err = insert_with_cache_writes(db, query, usage_id, cache_writes)
    end

    db:release()

    if insert_err then
        return nil, "Failed to create token usage record: " .. tostring(insert_err)
    end

    return {
        usage_id = usage_id,
        user_id = user_id,
        context_id = options.context_id,
        model_id = model_id,
        prompt_tokens = prompt_tokens,
        completion_tokens = completion_tokens,
        thinking_tokens = thinking_tokens,
        cache_read_tokens = cache_read_tokens,
        cache_write_tokens = cache_write_tokens,
        cache_write_by_ttl = stored_by_ttl,
        timestamp = now
    }
end

-- Get usage summary within a time range
function token_usage_repo.get_summary(start_time, end_time)
    if not start_time or type(start_time) ~= "number" then
        return nil, "Start time is required and must be a number"
    end

    if not end_time or type(end_time) ~= "number" then
        return nil, "End time is required and must be a number"
    end

    local db, err = get_db()
    if err then
        return nil, err
    end

    local from_timestamp = time.unix(start_time, 0):utc():format(time.RFC3339)
    local to_timestamp = time.unix(end_time, 0):utc():format(time.RFC3339)

    -- Build the query to get overall summary with timestamp filtering
    local query = sql.builder.select(
            "SUM(prompt_tokens) as total_prompt_tokens",
            "SUM(completion_tokens) as total_completion_tokens",
            "SUM(thinking_tokens) as total_thinking_tokens",
            "SUM(cache_read_tokens) as total_cache_read_tokens",
            "SUM(cache_write_tokens) as total_cache_write_tokens",
            "COUNT(*) as request_count"
        )
        :from("token_usage")
        :where(sql.builder.expr("timestamp >= ? AND timestamp <= ?", from_timestamp, to_timestamp))

    -- Execute the query
    local executor = query:run_with(db)
    local results, err = executor:query()
    local by_ttl, breakdown_err = nil, nil
    if not err then
        by_ttl, breakdown_err = cache_writes_by(db, nil, "u.timestamp >= $1 AND u.timestamp <= $2",
            { from_timestamp, to_timestamp })
    end

    db:release()

    if err or breakdown_err then
        return nil, "Failed to get usage summary: " .. tostring(err or breakdown_err)
    end

    -- Default values if no results or no matching data
    local result = {
        total_prompt_tokens = 0,
        total_completion_tokens = 0,
        total_thinking_tokens = 0,
        total_cache_read_tokens = 0,
        total_cache_write_tokens = 0,
        cache_write_by_ttl = by_ttl and by_ttl[""],
        request_count = 0,
        total_tokens = 0
    }

    -- Only process results if they exist and have data
    if results and #results > 0 and results[1].total_prompt_tokens ~= nil then
        result.total_prompt_tokens = results[1].total_prompt_tokens or 0
        result.total_completion_tokens = results[1].total_completion_tokens or 0
        result.total_thinking_tokens = results[1].total_thinking_tokens or 0
        result.total_cache_read_tokens = results[1].total_cache_read_tokens or 0
        result.total_cache_write_tokens = results[1].total_cache_write_tokens or 0
        result.request_count = results[1].request_count or 0

        -- Calculate total tokens excluding cache tokens
        result.total_tokens = (result.total_prompt_tokens or 0) +
                             (result.total_completion_tokens or 0) +
                             (result.total_thinking_tokens or 0)
    end

    return result
end

-- Get usage data by time interval
function token_usage_repo.get_usage_by_time(start_time, end_time, interval)
    if not start_time or type(start_time) ~= "number" then
        return nil, "Start time is required and must be a number"
    end

    if not end_time or type(end_time) ~= "number" then
        return nil, "End time is required and must be a number"
    end

    -- Default interval is daily
    interval = interval or token_usage_repo.INTERVAL.DAY

    local db, err = get_db()
    if err then
        return nil, err
    end

    -- Different time grouping based on interval
    local time_group_expr
    local query_sql
    local breakdown_sql
    local params
    if tostring(db:type()) == "postgres" then
        intervalSQL = "1 " .. interval .. ""
        local series_sql = [[
WITH interval_seconds AS (
    SELECT
        CASE
            WHEN $1 = INTERVAL '1 hour' THEN 3600
            WHEN $1 = INTERVAL '1 day' THEN 86400
            WHEN $1 = INTERVAL '1 week' THEN 604800
            WHEN $1 = INTERVAL '1 month' THEN 2592000
            ELSE 3600 -- Default to hour if not matched
        END AS seconds
),
date_series AS (
    SELECT
        to_timestamp(time_bucket) AT TIME ZONE 'UTC' as bucket_start,
        to_timestamp(time_bucket + (SELECT seconds FROM interval_seconds)) AT TIME ZONE 'UTC' as bucket_end
    FROM
        generate_series(
            $2,  -- date_from (Integer timestamp)
            $3,  -- date_to (Integer timestamp)
            (SELECT seconds FROM interval_seconds)  -- Interval in seconds
        ) as time_bucket
)]]
        query_sql = series_sql .. [[,
aggregated_data AS (
    SELECT
        date_series.bucket_start,
        COALESCE(SUM(prompt_tokens), 0) as prompt_tokens,
        COALESCE(SUM(completion_tokens), 0) as completion_tokens,
        COALESCE(SUM(thinking_tokens), 0) as thinking_tokens,
        COALESCE(SUM(cache_read_tokens), 0) as cache_read_tokens,
        COALESCE(SUM(cache_write_tokens), 0) as cache_write_tokens,
        COUNT(token_usage.usage_id) as request_count
    FROM
        date_series
    LEFT JOIN
        token_usage ON timestamp >= bucket_start
                   AND timestamp < bucket_end
    GROUP BY
        date_series.bucket_start
    ORDER BY
        date_series.bucket_start
)
SELECT
    CASE
        WHEN $1 = INTERVAL '1 hour' THEN to_char(bucket_start, 'YYYY-MM-DD HH24:00')
        WHEN $1 = INTERVAL '1 day' THEN to_char(bucket_start, 'YYYY-MM-DD')
        WHEN $1 = INTERVAL '1 week' THEN to_char(bucket_start, 'YYYY-WW')
        WHEN $1 = INTERVAL '1 month' THEN to_char(bucket_start, 'YYYY-MM')
        ELSE to_char(bucket_start, 'YYYY-MM-DD HH24:MI:SS')
    END as time_period,
    EXTRACT(EPOCH FROM bucket_start)::bigint AS bucket_key,
    prompt_tokens,
    completion_tokens,
    thinking_tokens,
    cache_read_tokens,
    cache_write_tokens,
    request_count
FROM
    aggregated_data
ORDER BY
    bucket_start;
                        ]]
        breakdown_sql = series_sql .. [[
SELECT
    EXTRACT(EPOCH FROM date_series.bucket_start)::bigint AS bucket_key,
    w.ttl AS ttl,
    SUM(w.tokens) AS tokens
FROM
    date_series
JOIN
    token_usage u ON u.timestamp >= date_series.bucket_start
                 AND u.timestamp < date_series.bucket_end
JOIN
    token_usage_cache_writes w ON w.usage_id = u.usage_id
GROUP BY
    date_series.bucket_start, w.ttl
]]
        params = { intervalSQL, start_time, end_time }
    else
        -- SQLite implementation using recursive CTE
        local interval_seconds
        local date_format

        if interval == token_usage_repo.INTERVAL.HOUR then
            interval_seconds = 3600
            date_format = "%Y-%m-%d %H:00:00"
        elseif interval == token_usage_repo.INTERVAL.DAY then
            interval_seconds = 86400
            date_format = "%Y-%m-%d"
        elseif interval == token_usage_repo.INTERVAL.WEEK then
            interval_seconds = 604800
            date_format = "%Y-%W"
        elseif interval == token_usage_repo.INTERVAL.MONTH then
            interval_seconds = 2592000
            date_format = "%Y-%m"
        else
            db:release()
            return nil, "Invalid interval: must be hour, day, week, or month"
        end

        local series_sql = [[
WITH RECURSIVE
time_buckets(bucket_start, bucket_end) AS (
    -- Base case: first time bucket
    SELECT
        CAST(strftime('%s', ?1) AS INTEGER) as bucket_start,
        CAST(strftime('%s', ?1) AS INTEGER) + ?2 as bucket_end
    UNION ALL
    -- Recursive case: generate subsequent time buckets
    SELECT
        bucket_end,
        bucket_end + ?2
    FROM time_buckets
    -- This should terminate when we reach the end date
    WHERE bucket_end <= CAST(strftime('%s', ?3) AS INTEGER)
)]]
        query_sql = series_sql .. [[
SELECT
    datetime(bucket_start, 'unixepoch') as time_period,
    b.bucket_start AS bucket_key,
    COALESCE(SUM(t.prompt_tokens), 0) as prompt_tokens,
    COALESCE(SUM(t.completion_tokens), 0) as completion_tokens,
    COALESCE(SUM(t.thinking_tokens), 0) as thinking_tokens,
    COALESCE(SUM(t.cache_read_tokens), 0) as cache_read_tokens,
    COALESCE(SUM(t.cache_write_tokens), 0) as cache_write_tokens,
    COUNT(t.usage_id) as request_count
FROM
    time_buckets b
LEFT JOIN
    token_usage t ON CAST(strftime('%s', t.timestamp) AS INTEGER) >= b.bucket_start
                   AND CAST(strftime('%s', t.timestamp) AS INTEGER) < b.bucket_end
GROUP BY
    b.bucket_start
ORDER BY
    b.bucket_start

]]
        breakdown_sql = series_sql .. [[
SELECT
    b.bucket_start AS bucket_key,
    w.ttl AS ttl,
    SUM(w.tokens) AS tokens
FROM
    time_buckets b
JOIN
    token_usage t ON CAST(strftime('%s', t.timestamp) AS INTEGER) >= b.bucket_start
                   AND CAST(strftime('%s', t.timestamp) AS INTEGER) < b.bucket_end
JOIN
    token_usage_cache_writes w ON w.usage_id = t.usage_id
GROUP BY
    b.bucket_start, w.ttl
]]
        params = { time.unix(start_time, 0):utc():format(time.RFC3339), interval_seconds, time.unix(end_time, 0):utc():format(time.RFC3339) }

    end

    -- Execute with parameters - use query() instead of execute() for SELECT operations
    local results, err = db:query(query_sql, params)
    local breakdown_rows, breakdown_err = nil, nil
    if not err then
        breakdown_rows, breakdown_err = db:query(breakdown_sql, params)
    end

    db:release()

    if err or breakdown_err then
        return nil, "Failed to get usage by time: " .. tostring(err or breakdown_err)
    end

    -- Return empty array if no results
    if not results then
        results = {}
    end

    local by_bucket = {}
    for _, row in ipairs(breakdown_rows or {}) do
        local bucket_key = tostring(row.bucket_key)
        by_bucket[bucket_key] = by_bucket[bucket_key] or {}
        by_bucket[bucket_key][row.ttl] = row.tokens
    end

    -- Add total tokens for each period (excluding cache tokens)
    for i, period in ipairs(results) do
        period.total_tokens = (period.prompt_tokens or 0) +
            (period.completion_tokens or 0) +
            (period.thinking_tokens or 0)
        period.cache_write_by_ttl = by_bucket[tostring(period.bucket_key)]
        period.bucket_key = nil
    end

    return results
end

-- Get usage data by model
function token_usage_repo.get_usage_by_model(start_time, end_time)
    if not start_time or type(start_time) ~= "number" then
        return nil, "Start time is required and must be a number"
    end

    if not end_time or type(end_time) ~= "number" then
        return nil, "End time is required and must be a number"
    end

    local db, err = get_db()
    if err then
        return nil, err
    end


    local query
    if tostring(db:type()) == "postgres" then
        query = sql.builder.select(
                "model_id",
                "SUM(prompt_tokens) as prompt_tokens",
                "SUM(completion_tokens) as completion_tokens",
                "SUM(thinking_tokens) as thinking_tokens",
                "SUM(cache_read_tokens) as cache_read_tokens",
                "SUM(cache_write_tokens) as cache_write_tokens",
                "COUNT(*) as request_count"
            )
            :from("token_usage")
            :where(sql.builder.expr("timestamp >= $1 AND timestamp <= $2",
                time.unix(start_time, 0):utc():format(time.RFC3339),
                time.unix(end_time, 0):utc():format(time.RFC3339)
            ))
            :group_by("model_id")
            :order_by("(SUM(prompt_tokens), SUM(completion_tokens), SUM(thinking_tokens)) DESC")
    else
        query = sql.builder.select(
                "model_id",
                "SUM(prompt_tokens) as prompt_tokens",
                "SUM(completion_tokens) as completion_tokens",
                "SUM(thinking_tokens) as thinking_tokens",
                "SUM(cache_read_tokens) as cache_read_tokens",
                "SUM(cache_write_tokens) as cache_write_tokens",
                "COUNT(*) as request_count"
            )
            :from("token_usage")
            :where(sql.builder.expr("timestamp >= $1 AND timestamp <= $2",
                time.unix(start_time, 0):utc():format(time.RFC3339),
                time.unix(end_time, 0):utc():format(time.RFC3339)
            ))
            :group_by("model_id")
            :order_by("(prompt_tokens + completion_tokens + thinking_tokens) DESC")
    end

    -- Execute the query
    local executor = query:run_with(db)
    local results, err = executor:query()
    local by_model, breakdown_err = nil, nil
    if not err then
        by_model, breakdown_err = cache_writes_by(db, "u.model_id", "u.timestamp >= $1 AND u.timestamp <= $2",
            report_bounds(start_time, end_time))
    end

    db:release()

    if err or breakdown_err then
        return nil, "Failed to get usage by model: " .. tostring(err or breakdown_err)
    end

    -- Return empty array if no results
    if not results then
        results = {}
    end

    -- Add total tokens for each model (excluding cache tokens)
    for i, model in ipairs(results) do
        model.total_tokens = (model.prompt_tokens or 0) +
            (model.completion_tokens or 0) +
            (model.thinking_tokens or 0)
        model.cache_write_by_ttl = by_model and by_model[tostring(model.model_id)]
    end

    return results
end

-- Get usage data grouped by user
function token_usage_repo.get_usage_by_user(start_time, end_time)
    if not start_time or type(start_time) ~= "number" then
        return nil, "Start time is required and must be a number"
    end

    if not end_time or type(end_time) ~= "number" then
        return nil, "End time is required and must be a number"
    end

    local db, err = get_db()
    if err then
        return nil, err
    end

    local query
    if tostring(db:type()) == "postgres" then
        query = sql.builder.select(
                "user_id",
                "SUM(prompt_tokens) as prompt_tokens",
                "SUM(completion_tokens) as completion_tokens",
                "SUM(thinking_tokens) as thinking_tokens",
                "SUM(cache_read_tokens) as cache_read_tokens",
                "SUM(cache_write_tokens) as cache_write_tokens",
                "COUNT(*) as request_count"
            )
            :from("token_usage")
            :where(sql.builder.expr("timestamp >= $1 AND timestamp <= $2",
                time.unix(start_time, 0):utc():format(time.RFC3339),
                time.unix(end_time, 0):utc():format(time.RFC3339)
            ))
            :group_by("user_id")
            :order_by("(SUM(prompt_tokens) + SUM(completion_tokens) + SUM(thinking_tokens)) DESC")
    else
        query = sql.builder.select(
                "user_id",
                "SUM(prompt_tokens) as prompt_tokens",
                "SUM(completion_tokens) as completion_tokens",
                "SUM(thinking_tokens) as thinking_tokens",
                "SUM(cache_read_tokens) as cache_read_tokens",
                "SUM(cache_write_tokens) as cache_write_tokens",
                "COUNT(*) as request_count"
            )
            :from("token_usage")
            :where(sql.builder.expr("timestamp >= $1 AND timestamp <= $2",
                time.unix(start_time, 0):utc():format(time.RFC3339),
                time.unix(end_time, 0):utc():format(time.RFC3339)
            ))
            :group_by("user_id")
            :order_by("(prompt_tokens + completion_tokens + thinking_tokens) DESC")
    end

    local executor = query:run_with(db)
    local results, err = executor:query()
    local by_user, breakdown_err = nil, nil
    if not err then
        by_user, breakdown_err = cache_writes_by(db, "u.user_id", "u.timestamp >= $1 AND u.timestamp <= $2",
            report_bounds(start_time, end_time))
    end

    db:release()

    if err or breakdown_err then
        return nil, "Failed to get usage by user: " .. tostring(err or breakdown_err)
    end

    if not results then
        results = {}
    end

    for _, user in ipairs(results) do
        user.total_tokens = (user.prompt_tokens or 0) +
            (user.completion_tokens or 0) +
            (user.thinking_tokens or 0)
        user.cache_write_by_ttl = by_user and by_user[tostring(user.user_id)]
    end

    return results
end

return token_usage_repo
