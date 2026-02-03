local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local env = require("env")

-- Constants
local DEFAULT_SEARCH_LIMIT = 10

local embedding_repo = {}

-- Helper function to get database connection
local function get_db()
    local DB_RESOURCE, _ = env.get("wippy.embeddings.env:target_db")

    local db, err = sql.get(DB_RESOURCE)
    if err then
        return nil, "Failed to connect to database: " .. err
    end
    return db
end

-- Helper function to determine database type
local function get_db_type(db)
    local db_type, err = db:type()
    if err then
        return nil, "Failed to determine database type: " .. err
    end
    return db_type
end

-- Helper function to format embedding based on database type
local function format_embedding_for_db(embedding, db_type)
    if db_type == sql.type.POSTGRES then
        -- PostgreSQL expects array format
        return "[" .. table.concat(embedding, ",") .. "]"
    else
        -- SQLite expects JSON array format
        return "[" .. table.concat(embedding, ",") .. "]"
    end
end

-- Helper function to encode metadata to JSON based on database type
local function encode_meta_for_db(meta, db_type)
    if not meta then
        return nil
    end

    if type(meta) ~= "table" then
        return tostring(meta)
    end

    local encoded, err = json.encode(meta)
    if err then
        return nil, "Failed to encode metadata: " .. err
    end

    return encoded
end

-- Helper function to decode JSON metadata from database
local function decode_meta_from_db(meta_json)
    if not meta_json or meta_json == "" then
        return {}
    end

    local decoded, err = json.decode(meta_json)
    if err then
        -- If we can't decode, return empty table as fallback
        return {}
    end

    return decoded
end

-- Add a new embedding
-- @param content (string) - The text content to embed
-- @param content_type (string) - Type of content (e.g., "document_chunk", "question", etc.)
-- @param origin_id (string) - UUID of the source document/content
-- @param context_id (string) - Any string identifier for context (section ID, chat ID, etc.)
-- @param meta (table) - Optional metadata as a table
-- @param embedding (table) - Pre-generated embedding vector
function embedding_repo.add(content, content_type, origin_id, context_id, meta, embedding)
    if not content or content == "" then
        return nil, "Content is required"
    end

    if not content_type or content_type == "" then
        return nil, "Content type is required"
    end

    if not origin_id or origin_id == "" then
        return nil, "Origin ID is required"
    end

    if not embedding or #embedding == 0 then
        return nil, "Embedding is required"
    end

    -- Get database connection
    local db, err = get_db()
    if err then
        return nil, err
    end

    -- Determine database type
    local db_type, err = get_db_type(db)
    if err then
        db:release()
        return nil, err
    end

    -- Format embedding for database
    local embedding_formatted = format_embedding_for_db(embedding, db_type)

    -- Encode metadata to JSON if provided
    local meta_json = nil
    if meta then
        meta_json, err = encode_meta_for_db(meta, db_type)
        if err then
            db:release()
            return nil, err
        end
    end

    -- Generate a new UUID for entry_id
    local entry_id = uuid.v4()

    -- Insert embedding based on database type
    local query
    local executor
    local result, err

    if db_type == sql.type.POSTGRES then
        -- PostgreSQL query using query builder
        query = sql.builder.insert("embeddings_512")
            :set_map({
                entry_id = entry_id,
                origin_id = origin_id,
                content_type = content_type,
                context_id = context_id or sql.as.null(),
                -- embedding = sql.builder.expr("?::vector", embedding_formatted),
                embedding = embedding_formatted,
                content = content,
                meta = meta_json or sql.as.null()
            })
    else
        -- SQLite query with vec0 table using query builder
        query = sql.builder.insert("embeddings_512")
            :set_map({
                entry_id = entry_id,
                origin_id = origin_id,
                content_type = content_type,
                context_id = context_id or "",
                origin_id_aux = origin_id, -- Duplicate for SQLite filtering
                content = content,
                meta = meta_json or sql.as.null(),
                embedding = embedding_formatted
            })
    end

    executor = query:run_with(db)
    result, err = executor:exec()

    db:release()

    if err then
        return nil, "Failed to insert embedding: " .. err
    end

    return {
        entry_id = entry_id,
        origin_id = origin_id,
        content_type = content_type,
        context_id = context_id
    }
end

-- Add multiple embeddings in a single batch operation
-- @param batch (table) - Array of item tables with content, content_type, origin_id, context_id, meta, embedding
-- @return (table) - Array of results with entry_ids or error
function embedding_repo.add_batch(batch)
    if not batch or #batch == 0 then
        return nil, "Batch is empty"
    end

    -- Validate batch items
    for i, item in ipairs(batch) do
        -- Validate item fields
        if not item.content or item.content == "" then
            return nil, "Item " .. i .. ": Content is required"
        end

        if not item.content_type or item.content_type == "" then
            return nil, "Item " .. i .. ": Content type is required"
        end

        if not item.origin_id or item.origin_id == "" then
            return nil, "Item " .. i .. ": Origin ID is required"
        end

        if not item.embedding or #item.embedding == 0 then
            return nil, "Item " .. i .. ": Embedding is required"
        end
    end

    -- Get database connection
    local db, err = get_db()
    if err then
        return nil, err
    end

    -- Begin transaction
    local tx, err = db:begin()
    if err then
        db:release()
        return nil, "Failed to begin transaction: " .. err
    end

    -- Determine database type
    local db_type, err = get_db_type(db)
    if err then
        tx:rollback()
        db:release()
        return nil, err
    end

    -- Process each item and prepare for insertion
    local results = {}

    for i, item in ipairs(batch) do
        -- Generate a new UUID for entry_id
        local entry_id = uuid.v4()

        -- Format embedding for database
        local embedding_formatted = format_embedding_for_db(item.embedding, db_type)

        -- Encode metadata to JSON if provided
        local meta_json = nil
        if item.meta then
            meta_json, err = encode_meta_for_db(item.meta, db_type)
            if err then
                tx:rollback()
                db:release()
                return nil, "Item " .. i .. ": " .. err
            end
        end

        -- Insert embedding based on database type
        local query
        local executor
        local insert_result, insert_err

        if db_type == sql.type.POSTGRES then
            -- PostgreSQL query using query builder
            query = sql.builder.insert("embeddings_512")
                :set_map({
                    entry_id = entry_id,
                    origin_id = item.origin_id,
                    content_type = item.content_type,
                    context_id = item.context_id or sql.as.null(),
                    -- embedding = sql.builder.expr("?::vector", embedding_formatted),
                    embedding = embedding_formatted,
                    content = item.content,
                    meta = meta_json or sql.as.null()
                })
        else
            -- SQLite query with vec0 table using query builder
            query = sql.builder.insert("embeddings_512")
                :set_map({
                    entry_id = entry_id,
                    origin_id = item.origin_id,
                    content_type = item.content_type,
                    context_id = item.context_id or "",
                    origin_id_aux = item.origin_id, -- Duplicate for SQLite filtering
                    content = item.content,
                    meta = meta_json or sql.as.null(),
                    embedding = embedding_formatted
                })
        end

        executor = query:run_with(tx)
        insert_result, insert_err = executor:exec()

        if insert_err then
            tx:rollback()
            db:release()
            return nil, "Item " .. i .. ": Failed to insert embedding: " .. insert_err
        end

        -- Add result to results array
        table.insert(results, {
            entry_id = entry_id,
            origin_id = item.origin_id,
            content_type = item.content_type,
            context_id = item.context_id
        })
    end

    -- Commit transaction
    local commit_ok, commit_err = tx:commit()
    if not commit_ok then
        tx:rollback()
        db:release()
        return nil, "Failed to commit transaction: " .. commit_err
    end

    db:release()

    return {
        count = #results,
        items = results
    }
end

-- Get embeddings by origin_id
function embedding_repo.get_by_origin(origin_id)
    if not origin_id or origin_id == "" then
        return nil, "Origin ID is required"
    end

    -- Get database connection
    local db, err = get_db()
    if err then
        return nil, err
    end

    -- Determine database type
    local db_type, err = get_db_type(db)
    if err then
        db:release()
        return nil, err
    end

    -- Build the query using query builder
    local query = sql.builder.select(
            "entry_id", "origin_id", "content_type", "context_id",
            "content", "meta", "created_at", "updated_at"
        )
        :from("embeddings_512")

    if db_type == sql.type.POSTGRES then
        query = query:where("origin_id = ?", origin_id)
    else
        query = query:where("origin_id_aux = ?", origin_id)
    end

    -- Execute the query
    local executor = query:run_with(db)
    local results, err = executor:query()

    db:release()

    if err then
        return nil, "Failed to get embeddings: " .. err
    end

    -- Process the results: decode metadata JSON
    for i, result in ipairs(results) do
        if result.meta and result.meta ~= "" then
            results[i].meta = decode_meta_from_db(result.meta)
        else
            results[i].meta = {}
        end
    end

    return results
end

-- Delete embeddings by origin_id
function embedding_repo.delete_by_origin(origin_id)
    if not origin_id or origin_id == "" then
        return nil, "Origin ID is required"
    end

    -- Get database connection
    local db, err = get_db()
    if err then
        return nil, err
    end

    -- Determine database type
    local db_type, err = get_db_type(db)
    if err then
        db:release()
        return nil, err
    end

    -- Delete embeddings using query builder
    local query = sql.builder.delete("embeddings_512")

    if db_type == sql.type.POSTGRES then
        query = query:where("origin_id = ?", origin_id)
    else
        -- For SQLite, filter on origin_id_aux
        query = query:where("origin_id_aux = ?", origin_id)
    end

    local executor = query:run_with(db)
    local result, err = executor:exec()

    db:release()

    if err then
        return nil, "Failed to delete embeddings: " .. err
    end

    return {
        deleted = true,
        count = result.rows_affected
    }
end

-- Delete embedding by entry_id
function embedding_repo.delete_by_entry(entry_id)
    if not entry_id or entry_id == "" then
        return nil, "Entry ID is required"
    end

    -- Get database connection
    local db, err = get_db()
    if err then
        return nil, err
    end

    -- Delete embedding by entry_id using query builder
    local query = sql.builder.delete("embeddings_512")
        :where("entry_id = ?", entry_id)

    local executor = query:run_with(db)
    local result, err = executor:exec()

    db:release()

    if err then
        return nil, "Failed to delete embedding: " .. err
    end

    if result.rows_affected == 0 then
        return nil, "Embedding not found"
    end

    return {
        deleted = true
    }
end

-- Search for similar embeddings with filtering using a pre-generated embedding
function embedding_repo.search_by_embedding(embedding, options)
    if not embedding or #embedding == 0 then
        return nil, "Embedding vector is required"
    end

    options = options or {}
    local content_type = options.content_type
    local origin_id = options.origin_id
    local context_id = options.context_id
    local limit = options.limit or DEFAULT_SEARCH_LIMIT

    -- Get database connection
    local db, err = get_db()
    if err then
        return nil, err
    end

    -- Determine database type
    local db_type, err = get_db_type(db)
    if err then
        db:release()
        return nil, err
    end

    -- Format embedding for database
    local embedding_formatted = format_embedding_for_db(embedding, db_type)

    -- Build the search query based on database type
    local results, err

    if db_type == sql.type.POSTGRES then
        -- PostgreSQL vector search with filtering using query builder
        local select_builder = sql.builder.select(
            "entry_id", "origin_id", "content_type", "context_id",
            "content", "meta", "created_at", "updated_at",
            -- sql.builder.expr("1 - (embedding <=> ?::vector) as similarity", embedding_formatted)
            "1 - (embedding <=> '"..embedding_formatted.."') as similarity"
        )
        :from("embeddings_512")

        -- Add filters if provided
        if content_type then
            select_builder = select_builder:where("content_type = ?", content_type)
        end

        if origin_id then
            select_builder = select_builder:where("origin_id = ?", origin_id)
        end

        if context_id then
            select_builder = select_builder:where("context_id = ?", context_id)
        end

        -- Add ordering and limit
        select_builder = select_builder:order_by("similarity DESC"):limit(limit)

        -- Execute the query
        local executor = select_builder:run_with(db)
        results, err = executor:query()
    else
        -- SQLite vec0 vector search with filtering - need to use raw SQL for MATCH
        local query_conditions = {}
        local params = {}

        -- Main vector search condition
        table.insert(query_conditions, "embedding MATCH ?")
        table.insert(params, embedding_formatted)

        -- Add content_type filter if provided
        if content_type then
            table.insert(query_conditions, "content_type = ?")
            table.insert(params, content_type)
        end

        -- Add origin_id filter if provided (use origin_id_aux for SQLite)
        if origin_id then
            table.insert(query_conditions, "origin_id_aux = ?")
            table.insert(params, origin_id)
        end

        -- Add context_id filter if provided
        if context_id then
            table.insert(query_conditions, "context_id = ?")
            table.insert(params, context_id)
        end

        -- Build the WHERE clause
        local where_clause = table.concat(query_conditions, " AND ")

        -- Build the complete query
        local query_sql = [[
            SELECT
                entry_id,
                origin_id,
                content_type,
                context_id,
                content,
                meta,
                created_at,
                updated_at,
                1 - distance as similarity
            FROM embeddings_512
            WHERE ]] .. where_clause .. [[
            AND k = ?
            ORDER BY similarity DESC
        ]]

        -- Add the k parameter (limit)
        table.insert(params, limit)

        results, err = db:query(query_sql, params)
    end

    db:release()

    if err then
        return nil, "Search failed: " .. err
    end

    -- Process the results: decode metadata JSON
    for i, result in ipairs(results) do
        -- Decode metadata
        if result.meta and result.meta ~= "" then
            results[i].meta = decode_meta_from_db(result.meta)
        else
            results[i].meta = {}
        end
    end

    return results
end

return embedding_repo
