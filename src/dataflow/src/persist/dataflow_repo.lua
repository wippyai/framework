local sql = require("sql")
local json = require("json")
local time = require("time")

local DB_RESOURCE = "app:db"

local dataflow_repo = {}

local function get_db()
    local db, err = sql.get(DB_RESOURCE)
    if err then
        return nil, "Failed to connect to database: " .. err
    end
    return db
end

local function parse_dataflow_metadata(dataflow_row)
    if dataflow_row and dataflow_row.metadata and type(dataflow_row.metadata) == "string" then
        if dataflow_row.metadata == "" or dataflow_row.metadata == "{}" then
            dataflow_row.metadata = {}
        else
            local decoded, err_decode = json.decode(dataflow_row.metadata)
            if not err_decode then
                dataflow_row.metadata = decoded
            else
                dataflow_row.metadata = {}
            end
        end
    elseif dataflow_row and (dataflow_row.metadata == nil) then
        dataflow_row.metadata = {}
    end
    return dataflow_row
end

function dataflow_repo.get(dataflow_id)
    if not dataflow_id or dataflow_id == "" then return nil, "Workflow ID is required" end
    local db, err_db = get_db()
    if err_db then return nil, err_db end
    local query = sql.builder.select(
            "dataflow_id", "parent_dataflow_id", "actor_id",
            "type", "status", "metadata", "created_at", "updated_at"
        )
        :from("dataflows")
        :where("dataflow_id = ?", dataflow_id)
        :limit(1)
    local executor = query:run_with(db)
    local dataflows_data, err_query = executor:query()
    db:release()
    if err_query then return nil, "Failed to get dataflow: " .. err_query end
    if not dataflows_data or #dataflows_data == 0 then return nil, "Workflow not found" end
    return parse_dataflow_metadata(dataflows_data[1])
end

function dataflow_repo.get_by_user(dataflow_id, actor_id)
    if not dataflow_id or dataflow_id == "" then return nil, "Workflow ID is required" end
    if not actor_id or actor_id == "" then return nil, "Actor ID is required" end

    local db, err_db = get_db()
    if err_db then return nil, err_db end

    local query = sql.builder.select(
            "dataflow_id", "parent_dataflow_id", "actor_id",
            "type", "status", "metadata", "created_at", "updated_at"
        )
        :from("dataflows")
        :where(sql.builder.and_({
            sql.builder.eq({dataflow_id = dataflow_id}),
            sql.builder.eq({actor_id = actor_id})
        }))
        :limit(1)

    local executor = query:run_with(db)
    local dataflows_data, err_query = executor:query()
    db:release()

    if err_query then return nil, "Failed to get dataflow: " .. err_query end
    if not dataflows_data or #dataflows_data == 0 then return nil, "Workflow not found or access denied" end

    return parse_dataflow_metadata(dataflows_data[1])
end

function dataflow_repo.get_nodes_for_dataflow(dataflow_id)
    if not dataflow_id or dataflow_id == "" then return nil, "Workflow ID is required" end

    local db, err_db = get_db()
    if err_db then return nil, err_db end

    local nodes_query = sql.builder.select("*")
        :from("nodes")
        :where("dataflow_id = ?", dataflow_id)
        :order_by("node_id ASC")

    local nodes_executor = nodes_query:run_with(db)
    local nodes, err_nodes = nodes_executor:query()
    db:release()

    if err_nodes then return nil, "Failed to fetch dataflow nodes: " .. err_nodes end

    local processed_nodes = {}
    for i, node in ipairs(nodes or {}) do
        if node.metadata and type(node.metadata) == "string" then
            local decoded, err_decode = json.decode(node.metadata)
            if not err_decode then
                node.metadata = decoded
            else
                node.metadata = {}
            end
        else
            node.metadata = {}
        end

        if node.config and type(node.config) == "string" then
            local decoded_config, err_decode_config = json.decode(node.config)
            if not err_decode_config then
                node.config = decoded_config
            else
                node.config = {}
            end
        else
            node.config = {}
        end

        table.insert(processed_nodes, node)
    end

    return processed_nodes
end

function dataflow_repo.count_by_user(actor_id, filters)
    filters = filters or {}
    if not actor_id or actor_id == "" then return nil, "User ID is required" end

    local db, err_db = get_db()
    if err_db then return nil, err_db end

    local query_builder = sql.builder.select("COUNT(*) as total")
        :from("dataflows")
        :where("actor_id = ?", actor_id)

    if filters.status then query_builder = query_builder:where("status = ?", filters.status) end
    if filters.type then query_builder = query_builder:where("type = ?", filters.type) end
    if filters.parent_dataflow_id then
        if type(filters.parent_dataflow_id) == "string" and
           string.upper(filters.parent_dataflow_id) == "NULL" then
            query_builder = query_builder:where(sql.builder.expr("parent_dataflow_id IS NULL"))
        else
            query_builder = query_builder:where("parent_dataflow_id = ?", filters.parent_dataflow_id)
        end
    end

    local executor = query_builder:run_with(db)
    local result, err_query = executor:query()
    db:release()

    if err_query then return nil, "Failed to count dataflows: " .. err_query end
    if not result or #result == 0 then return 0 end

    return result[1].total or 0
end

function dataflow_repo.list_by_user(actor_id, filters)
    filters = filters or {}
    if not actor_id or actor_id == "" then return nil, "User ID is required" end
    local db, err_db = get_db()
    if err_db then return nil, err_db end
    local query_builder = sql.builder.select(
            "dataflow_id", "parent_dataflow_id", "actor_id",
            "type", "status", "metadata", "created_at", "updated_at"
        )
        :from("dataflows")
        :where("actor_id = ?", actor_id)
    if filters.status then query_builder = query_builder:where("status = ?", filters.status) end
    if filters.type then query_builder = query_builder:where("type = ?", filters.type) end
    if filters.parent_dataflow_id then
        if type(filters.parent_dataflow_id) == "string" and
           string.upper(filters.parent_dataflow_id) == "NULL" then
            query_builder = query_builder:where(sql.builder.expr("parent_dataflow_id IS NULL"))
        else
            query_builder = query_builder:where("parent_dataflow_id = ?", filters.parent_dataflow_id)
        end
    end
    query_builder = query_builder:order_by("created_at DESC")
    if filters.limit and type(filters.limit) == "number" and filters.limit > 0 then
        query_builder = query_builder:limit(filters.limit)
    end

    if filters.offset and type(filters.offset) == "number" and filters.offset >= 0 then
        query_builder = query_builder:offset(filters.offset)
    end

    local executor = query_builder:run_with(db)
    local dataflows_data, err_query = executor:query()
    db:release()

    if err_query then return nil, "Failed to list dataflows by user: " .. err_query end
    local result_dataflows = {}
    if dataflows_data then
        for _, wf_row in ipairs(dataflows_data) do
            table.insert(result_dataflows, parse_dataflow_metadata(wf_row))
        end
    end

    return result_dataflows
end

function dataflow_repo.list_children(parent_dataflow_id, filters)
    filters = filters or {}
    if not parent_dataflow_id or parent_dataflow_id == "" then return nil, "Parent Workflow ID is required" end
    local db, err_db = get_db()

    if err_db then return nil, err_db end

    local query_builder = sql.builder.select(
            "dataflow_id", "parent_dataflow_id", "actor_id",
            "type", "status", "metadata", "created_at", "updated_at"
        )
        :from("dataflows")
        :where("parent_dataflow_id = ?", parent_dataflow_id)

    if filters.status then query_builder = query_builder:where("status = ?", filters.status) end
    if filters.type then query_builder = query_builder:where("type = ?", filters.type) end

    query_builder = query_builder:order_by("created_at ASC")

    if filters.limit and type(filters.limit) == "number" and filters.limit > 0 then
        query_builder = query_builder:limit(filters.limit)
    end

    if filters.offset and type(filters.offset) == "number" and filters.offset >= 0 then
        query_builder = query_builder:offset(filters.offset)
    end

    local executor = query_builder:run_with(db)
    local dataflows_data, err_query = executor:query()
    db:release()

    if err_query then return nil, "Failed to list child dataflows: " .. err_query end
    local result_dataflows = {}
    if dataflows_data then
        for _, wf_row in ipairs(dataflows_data) do
            table.insert(result_dataflows, parse_dataflow_metadata(wf_row))
        end
    end
    return result_dataflows
end

return dataflow_repo