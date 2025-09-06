local sql = require("sql")
local time = require("time")
local uuid = require("uuid")
local json = require("json")
local consts = require("consts")

-- Use shared constants from consts
local constants = {
    COMMAND_TYPES = consts.COMMAND_TYPES,
    META_KEYS = consts.META_KEYS,
    STATUS = consts.STATUS,
}

-- Module to export
local ops = {}

-- Export constants for external use
ops.COMMAND_TYPES = constants.COMMAND_TYPES
ops.META_KEYS = constants.META_KEYS
ops.STATUS = constants.STATUS

-- ============================================================================
-- PRIVATE HANDLERS - IMPLEMENTATION DETAILS
-- ============================================================================

-- Define handlers for command types (private to this module)
local handlers = {}

-- Node Operations
handlers[constants.COMMAND_TYPES.CREATE_NODE] = function(tx, dataflow_id, op_id, command)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local payload = command.payload or {}

    if not payload.node_type then
        return nil, "Node type is required"
    end

    local node_id = payload.node_id or uuid.v7()
    local parent_node_id = payload.parent_node_id or sql.as.null()

    local metadata = payload.metadata or "{}"
    if type(metadata) == "table" then
        local encoded, err_encode = json.encode(metadata)
        if err_encode then
            return nil, "Failed to encode metadata: " .. err_encode
        end
        metadata = encoded
    end

    local config = payload.config or "{}"
    if type(config) == "table" then
        local encoded, err_encode = json.encode(config)
        if err_encode then
            return nil, "Failed to encode config: " .. err_encode
        end
        config = encoded
    end

    local status = payload.status or constants.STATUS.PENDING
    local now_ts = time.now():format(time.RFC3339NANO)

    local insert_query = sql.builder.insert("nodes")
        :set_map({
            node_id = node_id,
            dataflow_id = dataflow_id,
            parent_node_id = parent_node_id,
            type = payload.node_type,
            status = status,
            config = config,
            metadata = metadata,
            created_at = now_ts,
            updated_at = now_ts
        })

    local executor = insert_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, "Failed to create node: " .. err
    end

    return {
        node_id = node_id,
        changes_made = true,
        op_id = op_id
    }
end

handlers[constants.COMMAND_TYPES.UPDATE_NODE] = function(tx, dataflow_id, op_id, command)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local payload = command.payload or {}

    if not payload.node_id then
        return nil, "Node ID is required"
    end

    -- Metadata merge configuration - default is merge=true for consistency with UPDATE_WORKFLOW
    local merge_metadata = payload.merge_metadata
    if merge_metadata == nil then
        merge_metadata = true -- Default to merge
    end

    local update_query = sql.builder.update("nodes")
        :where("node_id = ?", payload.node_id)
        :where("dataflow_id = ?", dataflow_id)

    local has_update = false

    if payload.node_type then
        update_query = update_query:set("type", payload.node_type)
        has_update = true
    end

    if payload.status then
        update_query = update_query:set("status", payload.status)
        has_update = true
    end

    if payload.config then
        local config = payload.config
        if type(config) == "table" then
            local encoded, err_encode = json.encode(config)
            if err_encode then
                return nil, "Failed to encode config: " .. err_encode
            end
            config = encoded
        end
        update_query = update_query:set("config", config)
        has_update = true
    end

    if payload.metadata ~= nil then
        local meta_val_for_db

        if merge_metadata and payload.metadata then
            -- Read existing metadata first for merging
            local existing_query = sql.builder.select("metadata")
                :from("nodes")
                :where("node_id = ?", payload.node_id)
                :where("dataflow_id = ?", dataflow_id)

            local existing_executor = existing_query:run_with(tx)
            local existing_result, existing_err = existing_executor:query()

            if existing_err then
                return nil, "Failed to read existing metadata for merge: " .. existing_err
            end

            -- Parse existing metadata
            local existing_metadata = {}
            if #existing_result > 0 and existing_result[1].metadata then
                local existing_meta_str = existing_result[1].metadata
                if existing_meta_str and existing_meta_str ~= "" and existing_meta_str ~= "{}" then
                    local decoded, decode_err = json.decode(existing_meta_str)
                    if not decode_err and type(decoded) == "table" then
                        existing_metadata = decoded
                    end
                end
            end

            -- Parse new metadata
            local new_metadata = payload.metadata
            if type(new_metadata) == "string" then
                local decoded, decode_err = json.decode(new_metadata)
                if not decode_err and type(decoded) == "table" then
                    new_metadata = decoded
                elseif decode_err then
                    return nil, "Failed to decode new metadata JSON: " .. decode_err
                end
            end

            -- Merge metadata: existing + new (new overwrites existing keys)
            local merged_metadata = {}

            -- Copy existing metadata
            if type(existing_metadata) == "table" then
                for k, v in pairs(existing_metadata) do
                    merged_metadata[k] = v
                end
            end

            -- Overlay new metadata
            if type(new_metadata) == "table" then
                for k, v in pairs(new_metadata) do
                    merged_metadata[k] = v
                end
            end

            -- Encode merged result
            local encoded, err_json = json.encode(merged_metadata)
            if err_json then
                return nil, "Failed to encode merged metadata: " .. err_json
            end
            meta_val_for_db = encoded

        else
            -- Replacement mode (original behavior)
            if payload.metadata == nil then
                meta_val_for_db = sql.as.null()
            elseif type(payload.metadata) == "table" then
                local encoded, err_json = json.encode(payload.metadata)
                if err_json then
                    return nil, "Failed to encode metadata for update: " .. err_json
                end
                meta_val_for_db = encoded
            elseif type(payload.metadata) == "string" then
                meta_val_for_db = payload.metadata
            else
                return nil, "Invalid metadata type for update: must be a table, JSON string, or nil (for SQL NULL)"
            end
        end

        update_query = update_query:set("metadata", meta_val_for_db)
        has_update = true
    end

    if not has_update then
        return {
            node_id = payload.node_id,
            changes_made = false,
            op_id = op_id,
            message = "No fields provided for update"
        }
    end

    local now_ts = time.now():format(time.RFC3339NANO)
    update_query = update_query:set("updated_at", now_ts)

    local executor = update_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, "Failed to update node: " .. err
    end

    return {
        node_id = payload.node_id,
        changes_made = result.rows_affected > 0,
        op_id = op_id,
        rows_affected = result.rows_affected,
        metadata_merged = merge_metadata
    }
end

handlers[constants.COMMAND_TYPES.DELETE_NODE] = function(tx, dataflow_id, op_id, command)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local payload = command.payload or {}

    if not payload.node_id then
        return nil, "Node ID is required"
    end

    local delete_query = sql.builder.delete("nodes")
        :where("node_id = ?", payload.node_id)
        :where("dataflow_id = ?", dataflow_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, "Failed to delete node: " .. err
    end

    return {
        node_id = payload.node_id,
        changes_made = result.rows_affected > 0,
        op_id = op_id,
        rows_affected = result.rows_affected
    }
end

-- Data Operations
handlers[constants.COMMAND_TYPES.CREATE_DATA] = function(tx, dataflow_id, op_id, command)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local payload = command.payload or {}

    if not payload.data_type then
        return nil, "Data type is required"
    end

    if not payload.content then
        return nil, "Data content is required"
    end

    local data_id = payload.data_id or uuid.v7()
    local content_value = payload.content

    if type(content_value) == "table" then
        local encoded, err_encode = json.encode(content_value)
        if err_encode then
            return nil, "Failed to encode content: " .. err_encode
        end
        content_value = encoded
    end

    local content_type = payload.content_type or "application/json"
    local node_id = payload.node_id or sql.as.null()
    local metadata = payload.metadata or "{}"

    if type(metadata) == "table" then
        local encoded, err_encode = json.encode(metadata)
        if err_encode then
            return nil, "Failed to encode metadata: " .. err_encode
        end
        metadata = encoded
    end

    local now_ts = time.now():format(time.RFC3339NANO)

    local insert_query = sql.builder.insert("data")
        :set_map({
            data_id = data_id,
            dataflow_id = dataflow_id,
            node_id = node_id,
            type = payload.data_type,
            discriminator = payload.discriminator,
            key = payload.key,
            content = content_value,
            content_type = content_type,
            metadata = metadata,
            created_at = now_ts
        })

    local executor = insert_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, "Failed to create data record: " .. err
    end

    return {
        data_id = data_id,
        changes_made = true,
        op_id = op_id
    }
end

handlers[constants.COMMAND_TYPES.UPDATE_DATA] = function(tx, dataflow_id, op_id, command)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local payload = command.payload or {}

    if not payload.data_id then
        return nil, "Data ID is required"
    end

    local update_query = sql.builder.update("data")
        :where("data_id = ?", payload.data_id)
        :where("dataflow_id = ?", dataflow_id)

    local has_update = false

    if payload.content then
        local content_value = payload.content
        if type(content_value) == "table" then
            local encoded, err_encode = json.encode(content_value)
            if err_encode then
                return nil, "Failed to encode content: " .. err_encode
            end
            content_value = encoded
        end

        update_query = update_query:set("content", content_value)
        has_update = true
    end

    if payload.content_type then
        update_query = update_query:set("content_type", payload.content_type)
        has_update = true
    end

    if payload.metadata then
        local metadata = payload.metadata
        if type(metadata) == "table" then
            local encoded, err_encode = json.encode(metadata)
            if err_encode then
                return nil, "Failed to encode metadata: " .. err_encode
            end
            metadata = encoded
        end

        update_query = update_query:set("metadata", metadata)
        has_update = true
    end

    if not has_update then
        return {
            data_id = payload.data_id,
            changes_made = false,
            op_id = op_id,
            message = "No fields to update"
        }
    end

    local executor = update_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, "Failed to update data record: " .. err
    end

    return {
        data_id = payload.data_id,
        changes_made = result.rows_affected > 0,
        op_id = op_id,
        rows_affected = result.rows_affected
    }
end

handlers[constants.COMMAND_TYPES.DELETE_DATA] = function(tx, dataflow_id, op_id, command)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local payload = command.payload or {}

    if not payload.data_id then
        return nil, "Data ID is required"
    end

    local delete_query = sql.builder.delete("data")
        :where("data_id = ?", payload.data_id)
        :where("dataflow_id = ?", dataflow_id)

    local executor = delete_query:run_with(tx)
    local result, err = executor:exec()

    if err then
        return nil, "Failed to delete data record: " .. err
    end

    return {
        data_id = payload.data_id,
        changes_made = result.rows_affected > 0,
        op_id = op_id,
        rows_affected = result.rows_affected
    }
end

-- Workflow Operations
handlers[constants.COMMAND_TYPES.CREATE_WORKFLOW] = function(tx, dataflow_id, op_id, command)
    local payload = command.payload or {}

    if not payload.dataflow_id and not dataflow_id then
        return nil, "Workflow ID is required"
    end

    local wf_id = payload.dataflow_id or dataflow_id

    if not payload.actor_id then
        return nil, "User ID is required"
    end

    if not payload.type then
        return nil, "Workflow type is required"
    end

    local now_ts_str = time.now():format(time.RFC3339NANO)

    local meta_json_val_for_db = "{}"
    if payload.metadata ~= nil then
        if type(payload.metadata) == "table" then
            local encoded, err_json = json.encode(payload.metadata)
            if err_json then
                return nil, "Failed to encode metadata: " .. err_json
            end
            meta_json_val_for_db = encoded
        elseif type(payload.metadata) == "string" then
            meta_json_val_for_db = payload.metadata
        else
            return nil, "Invalid metadata type: must be a table or a JSON string"
        end
    end

    local insert_query = sql.builder.insert("dataflows")
        :set_map({
            dataflow_id = wf_id,
            parent_dataflow_id = payload.parent_dataflow_id or sql.as.null(),
            actor_id = payload.actor_id,
            type = payload.type,
            status = payload.status or "pending",
            metadata = meta_json_val_for_db,
            created_at = now_ts_str,
            updated_at = now_ts_str
        })

    local executor = insert_query:run_with(tx)
    local result_exec, err_exec = executor:exec()

    if err_exec then
        return nil, "Failed to create dataflow: " .. err_exec
    end

    return {
        dataflow_id = wf_id,
        changes_made = true,
        op_id = op_id
    }
end

handlers[constants.COMMAND_TYPES.UPDATE_WORKFLOW] = function(tx, dataflow_id, op_id, command)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local payload = command.payload or {}
    local wf_id_to_update = payload.dataflow_id or dataflow_id

    -- Metadata merge configuration - default is merge=true for consistency
    local merge_metadata = payload.merge_metadata
    if merge_metadata == nil then
        merge_metadata = true -- Default to merge
    end

    local update_query_builder = sql.builder.update("dataflows")
        :where("dataflow_id = ?", wf_id_to_update)

    local has_real_update_field = false

    if payload.type then
        update_query_builder = update_query_builder:set("type", payload.type)
        has_real_update_field = true
    end

    if payload.status then
        update_query_builder = update_query_builder:set("status", payload.status)
        has_real_update_field = true
    end

    if payload.last_commit_id then
        update_query_builder = update_query_builder:set("last_commit_id", payload.last_commit_id)
        has_real_update_field = true
    end

    if payload.metadata ~= nil then
        local meta_val_for_db

        if merge_metadata and payload.metadata then
            -- Read existing metadata first for merging
            local existing_query = sql.builder.select("metadata")
                :from("dataflows")
                :where("dataflow_id = ?", wf_id_to_update)

            local existing_executor = existing_query:run_with(tx)
            local existing_result, existing_err = existing_executor:query()

            if existing_err then
                return nil, "Failed to read existing metadata for merge: " .. existing_err
            end

            -- Parse existing metadata
            local existing_metadata = {}
            if #existing_result > 0 and existing_result[1].metadata then
                local existing_meta_str = existing_result[1].metadata
                if existing_meta_str and existing_meta_str ~= "" and existing_meta_str ~= "{}" then
                    local decoded, decode_err = json.decode(existing_meta_str)
                    if not decode_err and type(decoded) == "table" then
                        existing_metadata = decoded
                    end
                end
            end

            -- Parse new metadata
            local new_metadata = payload.metadata
            if type(new_metadata) == "string" then
                local decoded, decode_err = json.decode(new_metadata)
                if not decode_err and type(decoded) == "table" then
                    new_metadata = decoded
                elseif decode_err then
                    return nil, "Failed to decode new metadata JSON: " .. decode_err
                end
            end

            -- Merge metadata: existing + new (new overwrites existing keys)
            local merged_metadata = {}

            -- Copy existing metadata
            if type(existing_metadata) == "table" then
                for k, v in pairs(existing_metadata) do
                    merged_metadata[k] = v
                end
            end

            -- Overlay new metadata
            if type(new_metadata) == "table" then
                for k, v in pairs(new_metadata) do
                    merged_metadata[k] = v
                end
            end

            -- Encode merged result
            local encoded, err_json = json.encode(merged_metadata)
            if err_json then
                return nil, "Failed to encode merged metadata: " .. err_json
            end
            meta_val_for_db = encoded

        else
            -- Replacement mode (original behavior)
            if payload.metadata == nil then
                meta_val_for_db = sql.as.null()
            elseif type(payload.metadata) == "table" then
                local encoded, err_json = json.encode(payload.metadata)
                if err_json then
                    return nil, "Failed to encode metadata for update: " .. err_json
                end
                meta_val_for_db = encoded
            elseif type(payload.metadata) == "string" then
                meta_val_for_db = payload.metadata
            else
                return nil, "Invalid metadata type for update: must be a table, JSON string, or nil (for SQL NULL)"
            end
        end

        update_query_builder = update_query_builder:set("metadata", meta_val_for_db)
        has_real_update_field = true
    end

    if not has_real_update_field then
        return {
            dataflow_id = wf_id_to_update,
            changes_made = false,
            op_id = op_id,
            message = "No valid fields provided for update"
        }
    end

    update_query_builder = update_query_builder:set("updated_at", time.now():format(time.RFC3339NANO))

    local executor = update_query_builder:run_with(tx)
    local result_exec, err_exec = executor:exec()

    if err_exec then
        return nil, "Failed to update dataflow: " .. err_exec
    end

    if result_exec.rows_affected == 0 then
        return nil, "Workflow not found or no changes applied"
    end

    return {
        dataflow_id = wf_id_to_update,
        changes_made = true,
        op_id = op_id,
        rows_affected = result_exec.rows_affected,
        metadata_merged = merge_metadata
    }
end

handlers[constants.COMMAND_TYPES.DELETE_WORKFLOW] = function(tx, dataflow_id, op_id, command)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local payload = command.payload or {}
    local wf_id_to_delete = payload.dataflow_id or dataflow_id

    local delete_query = sql.builder.delete("dataflows")
        :where("dataflow_id = ?", wf_id_to_delete)

    local executor = delete_query:run_with(tx)
    local result_exec, err_exec = executor:exec()

    if err_exec then
        return nil, "Failed to delete dataflow: " .. err_exec
    end

    if result_exec.rows_affected == 0 then
        return nil, "Workflow not found"
    end

    return {
        dataflow_id = wf_id_to_delete,
        changes_made = true,
        op_id = op_id,
        rows_affected = result_exec.rows_affected,
        deleted = true
    }
end

-- Execute commands within a transaction
-- @param tx (sql.Transaction): Database transaction to use
-- @param dataflow_id (string): ID of the dataflow to operate on
-- @param op_id (string): Operation ID (generated if nil)
-- @param commands (table): Single command or array of commands
-- @return (table, string): Result of operations and error message if failed
function ops.execute(tx, dataflow_id, op_id, commands)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    -- Generate operation ID if not provided
    op_id = op_id or uuid.v7()

    -- Handle both single command and array of commands
    local command_array = {}
    if type(commands) == "table" and commands.type then
        -- Single command
        table.insert(command_array, commands)
    elseif type(commands) == "table" then
        -- Array of commands
        command_array = commands
    else
        return nil, "Commands must be a table or array of tables"
    end

    local changes_made = false
    local results = {}

    -- Check if any commands are CREATE_WORKFLOW operations for timestamp logic
    local has_workflow_creation = false
    for _, command in ipairs(command_array) do
        if command.type == constants.COMMAND_TYPES.CREATE_WORKFLOW then
            has_workflow_creation = true
            break
        end
    end

    for i, command in ipairs(command_array) do
        local handler = handlers[command.type]

        if not handler then
            return nil, "Unknown command type: " .. (command.type or "nil") .. " at index " .. i
        end

        if type(handler) ~= "function" then
            return nil, "Handler for command type " .. command.type .. " is not a function at index " .. i
        end

        -- Pass the same op_id to all handlers in this batch
        local result, err_handler = handler(tx, dataflow_id, op_id, command)

        if err_handler then
            return nil, "Error executing command at index " .. i .. ": " .. err_handler
        end

        -- Track if any command made changes
        if result and result.changes_made then
            changes_made = true
            result.input = command
        end

        -- Store command result
        table.insert(results, result)
    end

    -- Update dataflow timestamp for all operations EXCEPT when creating workflows
    -- CREATE_WORKFLOW sets its own timestamps during creation
    -- All other operations (CREATE_NODE, CREATE_DATA, UPDATE_*, DELETE_*) should update workflow timestamp
    if changes_made and not has_workflow_creation then
        local update_ts_sql_builder = sql.builder.update("dataflows")
            :set("updated_at", time.now():format(time.RFC3339NANO))
            :where("dataflow_id = ?", dataflow_id)

        local executor = update_ts_sql_builder:run_with(tx)
        local _, update_err = executor:exec()

        if update_err then
            return nil, "Commands succeeded but failed to update timestamp: " .. update_err
        end
    end

    return { results = results, changes_made = changes_made, op_id = op_id }, nil
end

return ops