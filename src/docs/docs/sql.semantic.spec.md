# Appendix: Vector and Text Search in Lua

This appendix covers advanced search capabilities in the SQL module, including vector similarity search, full-text search, and hybrid approaches combining both techniques.

## Vector Search

### Creating Vector Tables

```lua
local db, err = sql.get("db_resource_id")
if err then error(err) end

-- Create vector table
local ok, err = db:execute([[
    CREATE VIRTUAL TABLE IF NOT EXISTS documents USING vec0(
        doc_id INTEGER PRIMARY KEY,
        embedding float[384],         -- Vector with 384 dimensions
        category TEXT,                -- Metadata for filtering
        +title TEXT,                  -- Auxiliary data (with + prefix)
        +summary TEXT                 -- Auxiliary data
    )
]])
if err then error("Failed to create table: " .. err) end
```

### Inserting Vectors

Vector data can be provided as JSON arrays:

```lua
-- Insert a document with vector embedding
local ok, err = db:execute(
    "INSERT INTO documents(doc_id, embedding, category, title, summary) VALUES (CAST(? AS INTEGER), ?, ?, ?, ?)",
    {1, "[0.1, 0.2, 0.3, ...]", "article", "Vector Search Introduction", "An overview of vector search technology"}
)
if err then error("Failed to insert: " .. err) end
```

**Note:** Always use `CAST(? AS INTEGER)` for primary key values, as Lua numbers are floating-point by default.

### Vector Similarity Search

Perform a k-nearest neighbors (KNN) search:

```lua
-- Find similar documents
local query_vec = "[0.1, 0.2, 0.3, ...]"  -- Your query vector

local results, err = db:query([[
    SELECT
        doc_id,
        title,
        summary,
        distance           -- Similarity score
    FROM documents
    WHERE embedding MATCH ?
    AND k = 5              -- Return top 5 matches
    ORDER BY distance      -- Sort by similarity
]], {query_vec})

if err then error("Search failed: " .. err) end

-- Process results
for i, doc in ipairs(results) do
    print(string.format("Match %d: %s (distance: %.4f)", 
        i, doc.title, doc.distance))
end
```

### Filtered Vector Search

Combine vector search with metadata filtering:

```lua
-- Find similar articles in a specific category
local results, err = db:query([[
    SELECT
        doc_id,
        title,
        summary,
        distance
    FROM documents
    WHERE embedding MATCH ?
    AND category = 'article'    -- Metadata filter
    AND k = 5
    ORDER BY distance
]], {query_vec})
```

## Full-Text Search

### Creating Text Search Tables

```lua
-- Create text search table
local ok, err = db:execute([[
    CREATE VIRTUAL TABLE IF NOT EXISTS doc_content USING fts5(
        doc_id UNINDEXED,
        title,
        content,
        summary
    )
]])
if err then error("Failed to create text search table: " .. err) end
```

### Indexing Text Data

```lua
-- Add content to the index
local ok, err = db:execute(
    "INSERT INTO doc_content(doc_id, title, content, summary) VALUES (?, ?, ?, ?)",
    {1, "Vector Search Introduction", "Vector search enables similarity-based retrieval...", "An overview of vector search technology"}
)
if err then error("Indexing failed: " .. err) end
```

### Text Search with Ranking

Perform full-text search with BM25 ranking:

```lua
-- Search for documents about a topic
local query = "vector similarity search"

local results, err = db:query([[
    SELECT
        doc_id,
        title,
        highlight(doc_content, 1, '<b>', '</b>') AS title_highlighted,
        highlight(doc_content, 2, '<b>', '</b>') AS content_highlighted,
        bm25(doc_content) AS relevance
    FROM doc_content
    WHERE doc_content MATCH ?
    ORDER BY relevance
]], {query})

if err then error("Text search failed: " .. err) end
```

## Hybrid Search

Combine vector similarity with text relevance for more powerful search:

```lua
-- Perform hybrid search
local results, err = db:query([[
    WITH vector_matches AS (
        SELECT 
            doc_id,
            distance
        FROM documents
        WHERE embedding MATCH ?
        AND k = 10
    ),
    text_matches AS (
        SELECT 
            doc_id,
            bm25(doc_content) AS relevance
        FROM doc_content
        WHERE doc_content MATCH ?
    )
    SELECT 
        v.doc_id,
        d.title,
        d.summary,
        v.distance AS vector_distance,
        t.relevance AS text_relevance,
        -- Combined ranking score (adjust weights as needed)
        (1 - (v.distance / 2)) * 0.6 + (1 / (t.relevance + 1)) * 0.4 AS hybrid_score
    FROM vector_matches v
    JOIN text_matches t ON v.doc_id = t.doc_id
    JOIN documents d ON v.doc_id = d.doc_id
    ORDER BY hybrid_score DESC
    LIMIT 5
]], {query_vector, text_query})
```

## Vector Operations

The SQL module provides several functions for working with vectors:

```lua
-- Vector length
local result = db:query("SELECT vec_length(?)", {"[0.1, 0.2, 0.3, 0.4]"})

-- Distance between vectors (Euclidean)
local result = db:query("SELECT vec_distance_L2(?, ?)", 
    {"[0.1, 0.1]", "[0.2, 0.2]"})

-- Cosine distance (1 - cosine similarity)
local result = db:query("SELECT vec_distance_cosine(?, ?)", 
    {"[0.1, 0.1]", "[0.2, 0.2]"})

-- Vector normalization (L2)
local result = db:query("SELECT vec_normalize(?)", 
    {"[2, 3, 1, -4]"})

-- Add vectors
local result = db:query("SELECT vec_add(?, ?)",
    {"[1, 2, 3]", "[4, 5, 6]"})
```

## Vector Table Structure

When creating vector tables with `vec0`, you can use different column types:

1. **Primary Key**: Required integer identifier
   ```
   doc_id INTEGER PRIMARY KEY
   ```

2. **Vector Column**: Specify dimension and type
   ```
   embedding float[384]    -- 384-dimensional float vector
   small_vec int8[128]     -- 128-dimensional 8-bit integer vector
   binary_vec bit[256]     -- 256-dimensional binary vector
   ```

3. **Metadata Columns**: Regular columns used for filtering
   ```
   category TEXT
   price FLOAT
   is_active BOOLEAN
   ```

4. **Partition Key Columns**: For efficient filtering on common values
   ```
   user_id INTEGER PARTITION KEY
   ```

5. **Auxiliary Columns**: Data that's only retrieved, not filtered on
   ```
   +title TEXT
   +description TEXT
   +image_data BLOB
   ```

## Best Practices

1. **Primary Keys**: Always use `CAST(? AS INTEGER)` when inserting primary key values

2. **Vector Dimensions**: Ensure query vectors have the same dimension as indexed vectors

3. **Performance**:
   - Use metadata columns for frequently filtered fields
   - Use partition keys for high-cardinality filters
   - Keep auxiliary data in the vector table to avoid additional JOINs

4. **Hybrid Search**:
   - Tune the weighting between vector and text scores based on your use case
   - Consider query-time adjustments to emphasize either semantic or lexical matching

5. **Complex Scenarios**:
   - Use transactions for batch operations
   - Consider creating staged indexes for very large datasets

## Complete Example: AI-Powered Document Search

```lua
-- Setup schema for document search system
local function setup_search_system(db)
    -- Vector embeddings table with metadata
    db:execute([[
        CREATE VIRTUAL TABLE IF NOT EXISTS documents USING vec0(
            doc_id INTEGER PRIMARY KEY,
            embedding float[384],
            doc_type TEXT,                -- For filtering by document type
            creation_date TEXT,           -- For filtering by date
            +title TEXT,                  -- Document title
            +author TEXT,                 -- Document author
            +summary TEXT                 -- Document summary
        )
    ]])
    
    -- Full-text content index
    db:execute([[
        CREATE VIRTUAL TABLE IF NOT EXISTS doc_content USING fts5(
            doc_id UNINDEXED,
            title,
            content,
            summary
        )
    ]])
    
    return true
end

-- Add a document to the search system
local function index_document(db, doc)
    -- Start transaction for atomicity
    local tx, err = db:begin()
    if err then error("Failed to begin transaction: " .. err) end
    
    -- Insert vector representation
    local ok, err = tx:execute(
        "INSERT INTO documents VALUES (CAST(? AS INTEGER), ?, ?, ?, ?, ?, ?)",
        {doc.id, doc.embedding, doc.type, doc.date, doc.title, doc.author, doc.summary}
    )
    if err then
        tx:rollback()
        error("Failed to insert document vector: " .. err)
    end
    
    -- Insert textual content for full-text search
    ok, err = tx:execute(
        "INSERT INTO doc_content VALUES (?, ?, ?, ?)",
        {doc.id, doc.title, doc.content, doc.summary}
    )
    if err then
        tx:rollback()
        error("Failed to index document content: " .. err)
    end
    
    -- Commit transaction
    ok, err = tx:commit()
    if err then error("Failed to commit transaction: " .. err) end
    
    return true
end

-- Search function that combines vector and text search
local function search_documents(db, query_embedding, query_text, filters)
    -- Build filter conditions
    local filter_conditions = ""
    local filter_params = {}
    
    if filters then
        if filters.doc_type then
            filter_conditions = filter_conditions .. " AND doc_type = ?"
            table.insert(filter_params, filters.doc_type)
        end
        
        if filters.date_from then
            filter_conditions = filter_conditions .. " AND creation_date >= ?"
            table.insert(filter_params, filters.date_from)
        end
    end
    
    -- Prepare all query parameters
    local params = {query_embedding}
    for _, param in ipairs(filter_params) do
        table.insert(params, param)
    end
    table.insert(params, query_text)
    
    -- Perform hybrid search
    local query = [[
        WITH vector_matches AS (
            SELECT 
                doc_id,
                distance
            FROM documents
            WHERE embedding MATCH ?
            ]] .. filter_conditions .. [[
            AND k = 20
        ),
        text_matches AS (
            SELECT 
                doc_id,
                bm25(doc_content) AS relevance
            FROM doc_content
            WHERE doc_content MATCH ?
        )
        SELECT 
            v.doc_id,
            d.title,
            d.author,
            d.summary,
            v.distance AS vector_distance,
            t.relevance AS text_relevance,
            -- Hybrid score calculation
            (1 - (v.distance / 2)) * 0.6 + (1 / (t.relevance + 1)) * 0.4 AS score,
            highlight(doc_content, 2, '<mark>', '</mark>') AS content_highlight
        FROM vector_matches v
        JOIN text_matches t ON v.doc_id = t.doc_id
        JOIN documents d ON v.doc_id = d.doc_id
        ORDER BY score DESC
        LIMIT 10
    ]]
    
    local results, err = db:query(query, params)
    if err then error("Search failed: " .. err) end
    
    return results
end
```