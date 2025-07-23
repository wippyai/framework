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