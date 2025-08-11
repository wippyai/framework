local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local env = require("env")

-- Get database resource from environment
local DB_RESOURCE, _ = env.get("wippy.usage:target_db")

local token_usage_repo = {}

-- Constants for time intervals
token_usage_repo.INTERVAL = {
    HOUR = "hour",
    DAY = "day",
    WEEK = "week",
    MONTH = "month"
}

-- Get a database connection
local function get_db()
    local db, err = sql.get(DB_RESOURCE)
    if err then
        return nil, "Failed to connect to database: " .. err
    end
    return db
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
    if options.meta then
        if type(options.meta) == "table" then
            local encoded, err = json.encode(options.meta)
            if err then
                return nil, "Failed to encode meta: " .. err
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

    -- local now = options.timestamp or os.time()
    local now
    if options.timestamp == nil then
        now = time.now():utc():format(time.RFC3339)
    else
        now = time.unix(options.timestamp, 0):format(time.RFC3339) -- do not convert to UTC
    end

    local usage_id = uuid.v7()

    -- Extract the new token types from options
    local thinking_tokens = options.thinking_tokens or 0
    local cache_read_tokens = options.cache_read_tokens or 0
    local cache_write_tokens = options.cache_write_tokens or 0

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
    local result, err = query:run_with(db):exec()

    db:release()

    if err then
        return nil, "Failed to create token usage record: " .. err
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
        :where(sql.builder.expr("timestamp >= ? AND timestamp <= ?",
            time.unix(start_time, 0):format(time.RFC3339),
            time.unix(end_time, 0):format(time.RFC3339)
        ))

    -- Execute the query
    local executor = query:run_with(db)
    local results, err = executor:query()

    db:release()

    if err then
        return nil, "Failed to get usage summary: " .. err
    end

    -- Default values if no results or no matching data
    local result = {
        total_prompt_tokens = 0,
        total_completion_tokens = 0,
        total_thinking_tokens = 0,
        total_cache_read_tokens = 0,
        total_cache_write_tokens = 0,
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
    local params
    if tostring(db:type()) == "postgres" then
        intervalSQL = "1 " .. interval .. ""
        query_sql = [[
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
        to_timestamp(time_bucket) as bucket_start,
        to_timestamp(time_bucket) + $1 as bucket_end
    FROM
        generate_series(
            $2,  -- date_from (Integer timestamp)
            $3,  -- date_to (Integer timestamp)
            (SELECT seconds FROM interval_seconds)  -- Interval in seconds
        ) as time_bucket
),
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
    prompt_tokens,
    completion_tokens,
    thinking_tokens,
    cache_read_tokens,
    cache_write_tokens,
    request_count
FROM
    aggregated_data;
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
        
        query_sql = [[
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
)
SELECT
    datetime(bucket_start, 'unixepoch') as time_period,
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
        params = { time.unix(start_time, 0):format(time.RFC3339), interval_seconds, time.unix(end_time, 0):format(time.RFC3339) }

    end

    -- Execute with parameters - use query() instead of execute() for SELECT operations
    local results, err = db:query(query_sql, params)

    db:release()

    if err then
        return nil, "Failed to get usage by time: " .. err
    end

    -- Return empty array if no results
    if not results then
        results = {}
    end

    -- Add total tokens for each period (excluding cache tokens)
    for i, period in ipairs(results) do
        period.total_tokens = (period.prompt_tokens or 0) +
            (period.completion_tokens or 0) +
            (period.thinking_tokens or 0)
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
                os.date('%c', start_time),
                os.date('%c', end_time)
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
                time.unix(start_time, 0):format(time.RFC3339),
                time.unix(end_time, 0):format(time.RFC3339)
            ))
            :group_by("model_id")
            :order_by("(prompt_tokens + completion_tokens + thinking_tokens) DESC")
    end

    -- Execute the query
    local executor = query:run_with(db)
    local results, err = executor:query()

    db:release()

    if err then
        return nil, "Failed to get usage by model: " .. err
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
    end

    return results
end

return token_usage_repo