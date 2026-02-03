# Embeddings

Vector embeddings storage and similarity search with SQLite (vec0) and PostgreSQL (pgvector) support.

## Installation

```yaml
entries:
  - name: embeddings
    kind: ns.dependency
    component: wippy/embeddings
    version: "*"
    parameters:
      - name: target_db
        value: app:db
```

## Adding Embeddings

```lua
local embeddings = require("embeddings")

-- Add single embedding (auto-generated via LLM)
local result, err = embeddings.add(
    "This is the content to embed",
    "document_chunk",           -- content_type
    "doc-123",                  -- origin_id
    "section-1",                -- context_id (optional)
    {author = "John"}           -- meta (optional)
)
-- result.entry_id, result.origin_id, result.content_type
```

## Batch Processing

```lua
local result, err = embeddings.add_batch({
    {
        content = "First chunk of text",
        content_type = "document_chunk",
        origin_id = "doc-123",
        context_id = "section-1",
        meta = {page = 1}
    },
    {
        content = "Second chunk of text",
        content_type = "document_chunk",
        origin_id = "doc-123",
        context_id = "section-2"
    }
})
-- result.count, result.items[]
```

Batches automatically split based on token limits (8000 tokens per request).

## Similarity Search

```lua
-- Basic search
local results, err = embeddings.search("find similar content", {
    limit = 10
})

-- Filtered search
local results, err = embeddings.search("query text", {
    content_type = "document_chunk",
    origin_id = "doc-123",
    context_id = "section-1",
    limit = 5
})

-- Results include similarity scores
for _, result in ipairs(results) do
    print(result.content, result.similarity)
end
```

## Convenience Methods

```lua
-- Find by content type
local results = embeddings.find_by_type("query", "document_chunk", {
    limit = 10
})

-- Find within specific origin
local results = embeddings.find_by_origin("query", "doc-123", {
    content_type = "document_chunk",
    limit = 5
})
```

## Low-level Repository

For direct vector operations:

```lua
local embedding_repo = require("embedding_repo")

-- Add with pre-generated embedding vector
local result, err = embedding_repo.add(
    content, content_type, origin_id, context_id, meta,
    {0.1, 0.2, 0.3, ...}  -- 512-dim vector
)

-- Batch add with vectors
embedding_repo.add_batch({
    {
        content = "...",
        content_type = "...",
        origin_id = "...",
        embedding = {0.1, 0.2, ...}
    }
})

-- Search with pre-generated query vector
local results = embedding_repo.search_by_embedding(
    {0.1, 0.2, 0.3, ...},
    {content_type = "...", limit = 10}
)

-- Get embeddings by origin
local entries = embedding_repo.get_by_origin("doc-123")

-- Delete
embedding_repo.delete_by_origin("doc-123")
embedding_repo.delete_by_entry("entry-uuid")
```

## Database Schema

Requires `embeddings_512` table with vector column. Migration provided:

```yaml
entries:
  - name: 01_create_embeddings_table
    kind: function.lua
    meta:
      type: migration
      target_db: app:db
```

### PostgreSQL (pgvector)

```sql
CREATE TABLE embeddings_512 (
    entry_id UUID PRIMARY KEY,
    origin_id UUID NOT NULL,
    content_type VARCHAR(255) NOT NULL,
    context_id VARCHAR(255),
    embedding vector(512) NOT NULL,
    content TEXT NOT NULL,
    meta JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### SQLite (vec0)

```sql
CREATE VIRTUAL TABLE embeddings_512 USING vec0(
    entry_id TEXT PRIMARY KEY,
    origin_id TEXT NOT NULL,
    origin_id_aux TEXT,
    content_type TEXT NOT NULL,
    context_id TEXT,
    embedding float[512],
    content TEXT NOT NULL,
    meta TEXT,
    created_at TEXT,
    updated_at TEXT
);
```

## Configuration

Default embedding model: `text-embedding-3-small` with 512 dimensions.
