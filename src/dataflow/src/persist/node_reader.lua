local sql = require("sql")
local json = require("json")

local APP_DB = "app:db"

local node_reader = {}
local methods = {}
local reader_mt = { __index = methods }

function methods:_copy()
    local new_instance = {}
    for k, v in pairs(self) do
        new_instance[k] = v
    end
    return setmetatable(new_instance, reader_mt)
end

local function normalize_args(args, arg_count)
    if arg_count == 1 and type(args[1]) == "table" and not getmetatable(args[1]) then
        return args[1]
    else
        return args
    end
end

function node_reader.with_dataflow(dataflow_id)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    local instance = {
        _dataflow_id = dataflow_id,
        _node_ids = nil,
        _parent_node_ids = nil,
        _node_types = nil,
        _statuses = nil,
        _excluded_statuses = nil,
        _fetch_config = true,
        _fetch_metadata = true,
    }
    return setmetatable(instance, reader_mt), nil
end

function methods:with_nodes(...)
    local args = { ... }
    local count = select("#", ...)
    local new_instance = self:_copy()
    new_instance._node_ids = normalize_args(args, count)
    return new_instance
end

function methods:with_parent_nodes(...)
    local args = { ... }
    local count = select("#", ...)
    local new_instance = self:_copy()
    new_instance._parent_node_ids = normalize_args(args, count)
    return new_instance
end

function methods:with_node_types(...)
    local args = { ... }
    local count = select("#", ...)
    local new_instance = self:_copy()
    new_instance._node_types = normalize_args(args, count)
    return new_instance
end

function methods:with_statuses(...)
    local args = { ... }
    local count = select("#", ...)
    local new_instance = self:_copy()
    new_instance._statuses = normalize_args(args, count)
    return new_instance
end

-- NEW: Filter by excluding specific statuses (for optimization)
function methods:with_statuses_excluded(...)
    local args = { ... }
    local count = select("#", ...)
    local new_instance = self:_copy()
    new_instance._excluded_statuses = normalize_args(args, count)
    return new_instance
end

function methods:fetch_options(options)
    if not options or type(options) ~= "table" then
        return self
    end

    local new_instance = self:_copy()

    if options.config ~= nil then
        new_instance._fetch_config = options.config
    end

    if options.metadata ~= nil then
        new_instance._fetch_metadata = options.metadata
    end

    return new_instance
end

local function create_in_clause(field, values)
    if not values or #values == 0 then
        return nil
    end

    if #values == 1 then
        return { field .. " = ?", values[1] }
    end

    local placeholders = {}
    for i = 1, #values do
        table.insert(placeholders, "?")
    end

    return { field .. " IN (" .. table.concat(placeholders, ", ") .. ")", unpack(values) }
end

-- NEW: Helper for NOT IN clause (for excluded statuses)
local function create_not_in_clause(field, values)
    if not values or #values == 0 then
        return nil
    end

    if #values == 1 then
        return { field .. " != ?", values[1] }
    end

    local placeholders = {}
    for i = 1, #values do
        table.insert(placeholders, "?")
    end

    return { field .. " NOT IN (" .. table.concat(placeholders, ", ") .. ")", unpack(values) }
end

function methods:_build_query()
    local select_fields = { "node_id", "dataflow_id", "parent_node_id", "type", "status",
        "created_at", "updated_at" }

    if self._fetch_config then
        table.insert(select_fields, "config")
    end

    if self._fetch_metadata then
        table.insert(select_fields, "metadata")
    end

    local query_builder = sql.builder.select(unpack(select_fields))
        :from("nodes")

    query_builder = query_builder:where("dataflow_id = ?", self._dataflow_id)

    if self._node_ids and #self._node_ids > 0 then
        local node_clause = create_in_clause("node_id", self._node_ids)
        if node_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(node_clause)))
        end
    end

    if self._parent_node_ids and #self._parent_node_ids > 0 then
        local parent_clause = create_in_clause("parent_node_id", self._parent_node_ids)
        if parent_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(parent_clause)))
        end
    end

    if self._node_types and #self._node_types > 0 then
        local type_clause = create_in_clause("type", self._node_types)
        if type_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(type_clause)))
        end
    end

    if self._statuses and #self._statuses > 0 then
        local status_clause = create_in_clause("status", self._statuses)
        if status_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(status_clause)))
        end
    end

    -- NEW: Handle excluded statuses
    if self._excluded_statuses and #self._excluded_statuses > 0 then
        local excluded_clause = create_not_in_clause("status", self._excluded_statuses)
        if excluded_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(excluded_clause)))
        end
    end

    query_builder = query_builder:order_by("created_at ASC")

    return query_builder
end

local function parse_json_field(field_str)
    if not field_str or type(field_str) ~= "string" then
        return {}
    end

    if field_str == "" or field_str == "{}" then
        return {}
    end

    local parsed, err = json.decode(field_str)
    if err then
        return {}
    else
        return parsed
    end
end

local function parse_json_fields(rows, fetch_config, fetch_metadata)
    for i, row in ipairs(rows) do
        if fetch_config then
            if row.config then
                row.config = parse_json_field(row.config)
            else
                row.config = {}
            end
        end

        if fetch_metadata then
            if row.metadata then
                row.metadata = parse_json_field(row.metadata)
            else
                row.metadata = {}
            end
        end
    end
    return rows
end

local function get_db()
    return sql.get(APP_DB)
end

function methods:all()
    local query_builder = self:_build_query()
    local db, db_err = get_db()
    if db_err then
        return nil, "Failed to connect to database: " .. db_err
    end

    local executor = query_builder:run_with(db)
    local results, err = executor:query()
    db:release()

    if err then
        return nil, "Failed to fetch nodes: " .. err
    end

    results = parse_json_fields(results, self._fetch_config, self._fetch_metadata)
    return results, nil
end

function methods:one()
    local query_builder = self:_build_query():limit(1)
    local db, db_err = get_db()
    if db_err then
        return nil, "Failed to connect to database: " .. db_err
    end

    local executor = query_builder:run_with(db)
    local results, err = executor:query()
    db:release()

    if err then
        return nil, "Failed to fetch node: " .. err
    end

    if #results == 0 then
        return nil, nil
    end

    results = parse_json_fields(results, self._fetch_config, self._fetch_metadata)
    return results[1], nil
end

function methods:count()
    local query_builder = sql.builder.select("COUNT(*) as count")
        :from("nodes")
        :where("dataflow_id = ?", self._dataflow_id)

    if self._node_ids and #self._node_ids > 0 then
        local node_clause = create_in_clause("node_id", self._node_ids)
        if node_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(node_clause)))
        end
    end

    if self._parent_node_ids and #self._parent_node_ids > 0 then
        local parent_clause = create_in_clause("parent_node_id", self._parent_node_ids)
        if parent_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(parent_clause)))
        end
    end

    if self._node_types and #self._node_types > 0 then
        local type_clause = create_in_clause("type", self._node_types)
        if type_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(type_clause)))
        end
    end

    if self._statuses and #self._statuses > 0 then
        local status_clause = create_in_clause("status", self._statuses)
        if status_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(status_clause)))
        end
    end

    -- NEW: Handle excluded statuses in count
    if self._excluded_statuses and #self._excluded_statuses > 0 then
        local excluded_clause = create_not_in_clause("status", self._excluded_statuses)
        if excluded_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(excluded_clause)))
        end
    end

    local db, db_err = get_db()
    if db_err then
        return nil, "Failed to connect to database: " .. db_err
    end

    local executor = query_builder:run_with(db)
    local results, err = executor:query()
    db:release()

    if err then
        return nil, "Failed to count nodes: " .. err
    end

    return results[1].count, nil
end

function methods:exists()
    local count, err = self:count()
    if err then
        return false, err
    end
    return count > 0, nil
end

-- NEW: Efficient status distribution counting
function methods:count_by_status()
    local query_builder = sql.builder.select("status", "COUNT(*) as count")
        :from("nodes")
        :where("dataflow_id = ?", self._dataflow_id)

    -- Apply all existing filters except status filters
    if self._node_ids and #self._node_ids > 0 then
        local node_clause = create_in_clause("node_id", self._node_ids)
        if node_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(node_clause)))
        end
    end

    if self._parent_node_ids and #self._parent_node_ids > 0 then
        local parent_clause = create_in_clause("parent_node_id", self._parent_node_ids)
        if parent_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(parent_clause)))
        end
    end

    if self._node_types and #self._node_types > 0 then
        local type_clause = create_in_clause("type", self._node_types)
        if type_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(type_clause)))
        end
    end

    -- Apply status filters if specified
    if self._statuses and #self._statuses > 0 then
        local status_clause = create_in_clause("status", self._statuses)
        if status_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(status_clause)))
        end
    end

    -- Apply excluded statuses if specified
    if self._excluded_statuses and #self._excluded_statuses > 0 then
        local excluded_clause = create_not_in_clause("status", self._excluded_statuses)
        if excluded_clause then
            query_builder = query_builder:where(sql.builder.expr(unpack(excluded_clause)))
        end
    end

    query_builder = query_builder:group_by("status"):order_by("status")

    local db, db_err = get_db()
    if db_err then
        return nil, "Failed to connect to database: " .. db_err
    end

    local executor = query_builder:run_with(db)
    local results, err = executor:query()
    db:release()

    if err then
        return nil, "Failed to count nodes by status: " .. err
    end

    -- Convert to map for easier access
    local status_counts = {}
    for _, row in ipairs(results) do
        status_counts[row.status] = row.count
    end

    return status_counts, nil
end

return node_reader