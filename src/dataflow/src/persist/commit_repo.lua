local sql = require("sql")
local json = require("json")
local time = require("time")

local DB_RESOURCE = "app:db"

local commit_repo = {}

-- Get database connection
local function get_db()
    local db, err = sql.get(DB_RESOURCE)
    if err then
        return nil, "Failed to connect to database: " .. err
    end
    return db
end

-- Parse JSON fields in commit data
local function parse_commit(commit_row)
    if not commit_row then
        return nil
    end

    -- Parse payload JSON
    if commit_row.payload and type(commit_row.payload) == "string" then
        local decoded, err = json.decode(commit_row.payload)
        if not err then
            commit_row.payload = decoded
        end
    end

    -- Parse metadata JSON
    if commit_row.metadata and type(commit_row.metadata) == "string" then
        local decoded, err = json.decode(commit_row.metadata)
        if not err then
            commit_row.metadata = decoded
        else
            commit_row.metadata = {}
        end
    elseif commit_row.metadata == nil then
        commit_row.metadata = {}
    end

    return commit_row
end

-- Create a new commit record
function commit_repo.create(commit_id, dataflow_id, payload, metadata)
    if not commit_id then
        return nil, "Commit ID is required"
    end

    if not dataflow_id then
        return nil, "Dataflow ID is required"
    end

    if not payload then
        return nil, "Payload is required"
    end

    local db, err_db = get_db()
    if err_db then
        return nil, err_db
    end

    -- Process payload - encode tables as JSON
    local payload_json
    if type(payload) == "table" then
        local encoded, err = json.encode(payload)
        if err then
            db:release()
            return nil, "Failed to encode payload: " .. err
        end
        payload_json = encoded
    else
        payload_json = tostring(payload)
    end

    -- Process metadata - encode tables as JSON or use empty object
    local metadata_json = "{}"
    if metadata ~= nil then
        if type(metadata) == "table" then
            local encoded, err = json.encode(metadata)
            if err then
                db:release()
                return nil, "Failed to encode metadata: " .. err
            end
            metadata_json = encoded
        elseif type(metadata) == "string" then
            metadata_json = metadata
        end
    end

    -- Create timestamp
    local created_at = time.now():format(time.RFC3339)

    -- Begin transaction
    local tx, err_tx = db:begin()
    if err_tx then
        db:release()
        return nil, "Failed to begin transaction: " .. err_tx
    end

    -- Insert the commit record
    local insert_query = sql.builder.insert("dataflow_commits")
        :set_map({
            commit_id = commit_id,
            dataflow_id = dataflow_id,
            op_id = sql.as.null(),
            execution_id = sql.as.null(),
            payload = payload_json,
            metadata = metadata_json,
            created_at = created_at
        })

    local executor = insert_query:run_with(tx)
    local result, err_exec = executor:exec()

    if err_exec then
        tx:rollback()
        db:release()
        return nil, "Failed to create commit: " .. err_exec
    end

    -- Update the dataflow's last_commit_id
    local update_query = sql.builder.update("dataflows")
        :set("last_commit_id", commit_id)
        :set("updated_at", created_at)
        :where("dataflow_id = ?", dataflow_id)

    executor = update_query:run_with(tx)
    local update_result, err_update = executor:exec()

    if err_update then
        tx:rollback()
        db:release()
        return nil, "Failed to update dataflow last commit ID: " .. err_update
    end

    -- Commit transaction
    local _, err_commit = tx:commit()
    if err_commit then
        tx:rollback()
        db:release()
        return nil, "Failed to commit transaction: " .. err_commit
    end

    db:release()

    -- Return the created commit
    return {
        commit_id = commit_id,
        dataflow_id = dataflow_id,
        payload = payload,
        metadata = type(metadata) == "table" and metadata or {},
        created_at = created_at
    }
end

-- Get a commit by ID
function commit_repo.get(commit_id)
    if not commit_id then
        return nil, "Commit ID is required"
    end

    local db, err_db = get_db()
    if err_db then
        return nil, err_db
    end

    local query = sql.builder.select("*")
        :from("dataflow_commits")
        :where("commit_id = ?", commit_id)
        :limit(1)

    local executor = query:run_with(db)
    local rows, err_query = executor:query()

    db:release()

    if err_query then
        return nil, "Failed to get commit: " .. err_query
    end

    if not rows or #rows == 0 then
        return nil, "Commit not found"
    end

    return parse_commit(rows[1])
end

-- Get commits for a dataflow, with stable ordering by commit_id
function commit_repo.list_by_dataflow(dataflow_id, options)
    if not dataflow_id then
        return nil, "Dataflow ID is required"
    end

    options = options or {}

    local db, err_db = get_db()
    if err_db then
        return nil, err_db
    end

    local query_builder = sql.builder.select("*")
        :from("dataflow_commits")
        :where("dataflow_id = ?", dataflow_id)

    -- Add filter for after_commit_id (get commits after a specific ID)
    if options.after_commit_id then
        query_builder = query_builder:where("commit_id > ?", options.after_commit_id)
    end

    -- Always order by commit_id for stable results
    -- UUID v7 has time component first, so this is chronological
    query_builder = query_builder:order_by("commit_id ASC")

    -- Add limit if specified
    if options.limit and tonumber(options.limit) > 0 then
        query_builder = query_builder:limit(tonumber(options.limit))
    end

    -- Add offset if specified
    if options.offset and tonumber(options.offset) >= 0 then
        query_builder = query_builder:offset(tonumber(options.offset))
    end

    local executor = query_builder:run_with(db)
    local rows, err_query = executor:query()

    db:release()

    if err_query then
        return nil, "Failed to list commits: " .. err_query
    end

    -- Parse JSON in all rows
    local commits = {}
    for _, row in ipairs(rows or {}) do
        table.insert(commits, parse_commit(row))
    end

    return commits
end

-- Get commits after a specific ID or all commits if ID is nil
function commit_repo.list_after(dataflow_id, after_commit_id)
    if not dataflow_id then
        return nil, "Dataflow ID is required"
    end

    -- If after_commit_id is nil, return all commits for the dataflow
    local options = {}
    if after_commit_id then
        options.after_commit_id = after_commit_id
    end

    return commit_repo.list_by_dataflow(dataflow_id, options)
end

return commit_repo