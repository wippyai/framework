local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local security = require("security")
local ops = require("ops")
local commit_repo = require("commit_repo")
local consts = require("consts")

local commit = {}

-- Helper function to get database connection
local function get_db()
    local db, err = sql.get(consts.APP_DB)
    if err then
        return nil, "Failed to connect to database: " .. err
    end
    return db
end

-- Isolated method for sending process messages (can be mocked in tests)
function commit._send_process_message(target_process, topic, payload)
    process.send(target_process, topic, payload)
end

-- Isolated method for getting current user ID (can be mocked in tests)
function commit._get_current_user_id()
    return security.actor():id()
end

-- Isolated method for getting current timestamp (can be mocked in tests)
function commit._get_current_timestamp()
    return time.now():format(time.RFC3339NANO)
end

-- Function to notify subscribers about dataflow changes
-- Send updates to the user process with topics "dataflows" and "dataflow:{dataflow_id}"
function commit.publish_updates(dataflow_id, op_id, result)
    if not result or not result.changes_made or not result.results then
        return
    end

    local user_id = commit._get_current_user_id()
    local user_process = "user." .. user_id
    local now_ts = commit._get_current_timestamp()

    local has_node_events = false
    local has_workflow_changes = false

    -- Process all operations
    for _, cmd_result in ipairs(result.results) do
        if not (cmd_result and cmd_result.changes_made and cmd_result.input) then
            goto continue
        end

        local cmd_type = cmd_result.input.type
        local payload = cmd_result.input.payload or {}

        -- Handle node operations
        if cmd_type == ops.COMMAND_TYPES.CREATE_NODE or
           cmd_type == ops.COMMAND_TYPES.UPDATE_NODE or
           cmd_type == ops.COMMAND_TYPES.DELETE_NODE then

            has_node_events = true

            local node_update = {
                dataflow_id = dataflow_id,
                node_id = cmd_result.node_id or payload.node_id,
                parent_node_id = payload.parent_node_id,
                op_type = cmd_type,
                updated_at = now_ts,
                node_type = payload.node_type,
                status = payload.status,
                metadata = payload.metadata,
                deleted = cmd_type == ops.COMMAND_TYPES.DELETE_NODE
            }

            commit._send_process_message(user_process, "dataflow:" .. dataflow_id, node_update)

        -- Track workflow operations
        elseif cmd_type == ops.COMMAND_TYPES.CREATE_WORKFLOW or
               cmd_type == ops.COMMAND_TYPES.UPDATE_WORKFLOW or
               cmd_type == ops.COMMAND_TYPES.DELETE_WORKFLOW then

            has_workflow_changes = true
        end

        ::continue::
    end

    -- Send workflow event ONLY if no node events and there are workflow changes
    if not has_node_events and has_workflow_changes then
        commit._send_process_message(user_process, "dataflow:" .. dataflow_id, {
            dataflow_id = dataflow_id,
            updated_at = now_ts
        })
    end
end

-- Execute commands directly with a transaction
-- @param tx (sql.Transaction): Database transaction to use
-- @param dataflow_id (string): ID of the dataflow to operate on
-- @param op_id (string): Operation ID (generated if nil)
-- @param commands (table): Array of command tables
-- @param options (table): Optional parameters
-- @return (table, string): Result of operations and error message if failed
function commit.tx_execute(tx, dataflow_id, op_id, commands, options)
    if not tx then
        return nil, "Transaction is required"
    end

    if not dataflow_id then
        return nil, "Dataflow ID is required"
    end

    if not commands or type(commands) ~= "table" or #commands == 0 then
        return nil, "Commands array cannot be empty"
    end

    -- Generate operation ID if not provided
    op_id = op_id or uuid.v7()
    options = options or {}

    -- Preprocess commands to handle COMMIT_COMMAND
    local processed_commands = {}
    local commit_ids = {} -- Track which commits we've processed

    -- First pass: Preprocess commands, expanding commits
    for i, command in ipairs(commands) do
        if command.type == consts.COMMAND.APPLY_COMMIT then
            local payload = command.payload or {}
            local commit_id = payload.commit_id

            if not commit_id then
                return nil, "Commit ID is required for COMMIT_COMMAND at index " .. i
            end

            -- Add to tracking list
            table.insert(commit_ids, commit_id)

            -- Get the commit from database
            local commit_query = sql.builder.select("*")
                :from("dataflow_commits")
                :where("commit_id = ?", commit_id)
                :where("dataflow_id = ?", dataflow_id)
                :limit(1)

            local executor = commit_query:run_with(tx)
            local commits, err_query = executor:query()

            if err_query then
                return nil, "Failed to query commit: " .. err_query .. " at index " .. i
            end

            if not commits or #commits == 0 then
                return nil, "Commit not found: " .. commit_id .. " at index " .. i
            end

            local commit_data = commits[1]

            -- Parse payload JSON
            local commit_payload
            if commit_data.payload and type(commit_data.payload) == "string" then
                local decoded, err = json.decode(commit_data.payload)
                if err then
                    return nil, "Failed to decode commit payload: " .. err
                end
                commit_payload = decoded
            else
                commit_payload = commit_data.payload
            end

            -- Extract commands from the commit payload
            local commit_commands = commit_payload.commands

            if not commit_commands then
                return nil, "No commands found in commit " .. commit_id .. " at index " .. i
            end

            -- Add all commit commands to our processed list
            for _, cmd in ipairs(commit_commands) do
                table.insert(processed_commands, cmd)
            end
        else
            -- Regular command, add as-is
            table.insert(processed_commands, command)
        end
    end

    -- Add commands to update last_commit_id for any commits we processed
    for _, commit_id in ipairs(commit_ids) do
        -- Add command to update the dataflow's last_commit_id
        table.insert(processed_commands, {
            type = ops.COMMAND_TYPES.UPDATE_WORKFLOW,
            payload = {
                dataflow_id = dataflow_id,
                last_commit_id = commit_id
            }
        })
    end

    -- Execute the processed operations within the provided transaction
    local result, err = ops.execute(tx, dataflow_id, op_id, processed_commands)
    if err then
        return nil, err
    end

    -- Add commit_ids to result for reference
    if #commit_ids > 0 then
        result.commit_ids = commit_ids
    end

    -- Handle publishing if enabled (default is true)
    if options.publish ~= false then
        commit.publish_updates(dataflow_id, op_id, result)
    end

    return result, nil
end

-- Execute commands directly (without using commit table)
-- Creates its own transaction and handles publishing
-- @param dataflow_id (string): ID of the dataflow to operate on
-- @param op_id (string): Operation ID (generated if nil)
-- @param commands (table): Array of command tables
-- @param options (table): Optional parameters
-- @return (table, string): Result of operations and error message if failed
function commit.execute(dataflow_id, op_id, commands, options)
    if not dataflow_id then
        return nil, "Dataflow ID is required"
    end

    if not commands then
        return nil, "Commands are required"
    end

    -- Ensure commands is always an array
    if type(commands) ~= "table" then
        return nil, "Commands must be an array of tables"
    end

    -- Check if commands is empty
    if #commands == 0 then
        return nil, "Commands array cannot be empty"
    end

    -- Generate operation ID if not provided
    op_id = op_id or uuid.v7()
    options = options or {}

    -- Get database connection
    local db, err_db = get_db()
    if err_db then
        return nil, err_db
    end

    -- Begin transaction
    local tx, err_tx = db:begin()
    if err_tx then
        db:release()
        return nil, "Failed to begin transaction: " .. err_tx
    end

    -- Execute the operations
    local result, err_op = commit.tx_execute(tx, dataflow_id, op_id, commands, { publish = false })

    -- Handle errors
    if err_op then
        tx:rollback()
        db:release()
        return nil, err_op
    end

    -- Commit the transaction
    local success, err_commit = tx:commit()
    if err_commit then
        tx:rollback()
        db:release()
        return nil, "Failed to commit transaction: " .. err_commit
    end

    -- Release the connection
    db:release()

    -- Handle publishing if enabled (default is true)
    if options.publish ~= false then
        commit.publish_updates(dataflow_id, op_id, result)
    end

    -- Return the result
    return result, nil
end

-- Create a commit in the database and send a notification
-- @param dataflow_id (string): ID of the dataflow to operate on
-- @param op_id (string): Operation ID (generated if nil)
-- @param commands (table): Array of command tables
-- @param context (table): Optional context data
-- @return (table, string): Result of the commit operation or error
function commit.submit(dataflow_id, op_id, commands, context)
    -- Validate inputs
    if not dataflow_id or dataflow_id == "" then
        return nil, "Dataflow ID is required"
    end

    if not commands or (type(commands) ~= "table") then
        return nil, "Commands must be a table or array of commands"
    end

    -- Generate op_id if not provided
    op_id = op_id or uuid.v7()

    -- Create payload for commit
    local payload = {
        op_id = op_id,
        commands = commands
    }

    -- Create commit in database using modified commit_repo that doesn't update last_commit_id
    local commit_id = uuid.v7()
    local commit_result, err = commit._create_commit_only(commit_id, dataflow_id, payload)
    if err then
        return nil, "Failed to create commit: " .. err
    end

    commit._send_process_message("dataflow." .. dataflow_id, consts.MESSAGE_TOPIC.COMMIT, {
        commit_id = commit_id,
        context = context or {},
    })

    -- Just return the commit ID
    return { commit_id = commit_id }, nil
end

-- Internal function to create commit without updating last_commit_id
-- This is what submit() should use instead of commit_repo.create()
function commit._create_commit_only(commit_id, dataflow_id, payload, metadata)
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
    local created_at = time.now():format(time.RFC3339NANO)

    -- Begin transaction
    local tx, err_tx = db:begin()
    if err_tx then
        db:release()
        return nil, "Failed to begin transaction: " .. err_tx
    end

    -- Insert the commit record only (don't update dataflow's last_commit_id)
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

-- Get pending commits for a dataflow that need to be processed
-- @param dataflow_id (string): ID of the dataflow
-- @return (table, string): Array of commit IDs or error message
function commit.get_pending_commits(dataflow_id)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Dataflow ID is required"
    end

    -- Get the dataflow to find the last processed commit
    local db, err_db = get_db()
    if err_db then
        return nil, err_db
    end

    local query = sql.builder.select("last_commit_id")
        :from("dataflows")
        :where("dataflow_id = ?", dataflow_id)
        :limit(1)

    local executor = query:run_with(db)
    local results, err_query = executor:query()

    if err_query then
        db:release()
        return nil, "Failed to query dataflow: " .. err_query
    end

    local after_commit_id = nil
    if results and #results > 0 then
        after_commit_id = results[1].last_commit_id
    end

    -- Query for pending commits
    local commits_query
    if after_commit_id then
        commits_query = sql.builder.select("commit_id")
            :from("dataflow_commits")
            :where("dataflow_id = ?", dataflow_id)
            :where("commit_id > ?", after_commit_id)
            :order_by("commit_id ASC")
    else
        commits_query = sql.builder.select("commit_id")
            :from("dataflow_commits")
            :where("dataflow_id = ?", dataflow_id)
            :order_by("commit_id ASC")
    end

    executor = commits_query:run_with(db)
    results, err_query = executor:query()
    db:release()

    if err_query then
        return nil, "Failed to query pending commits: " .. err_query
    end

    local commit_ids = {}
    for _, row in ipairs(results or {}) do
        table.insert(commit_ids, row.commit_id)
    end

    return commit_ids, nil
end

return commit
