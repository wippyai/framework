return require("migration").define(function()
    migration("Create embeddings_512 table for vector embeddings", function()
        -- PostgreSQL implementation
        database("postgres", function()
            up(function(db)
                -- Enable the pg_vector extension if not already enabled
                local success, err = db:execute([[
                    DO $$
                    BEGIN
                        IF NOT EXISTS (
                            SELECT 1 FROM pg_extension WHERE extname = 'vector'
                        ) THEN
                            CREATE EXTENSION IF NOT EXISTS vector;
                        END IF;
                    END
                    $$;
                ]])

                if err then
                    error("Failed to enable vector extension: " .. err)
                end

                -- Create the embeddings table
                success, err = db:execute([[
                    CREATE TABLE IF NOT EXISTS embeddings_512 (
                        entry_id UUID PRIMARY KEY,
                        origin_id UUID NOT NULL,
                        content_type VARCHAR(32) NOT NULL,
                        context_id TEXT,
                        embedding vector(512) NOT NULL,
                        content TEXT NOT NULL,
                        meta JSONB,
                        created_at timestamp NOT NULL DEFAULT NOW(),
                        updated_at timestamp NOT NULL DEFAULT NOW()
                    );
                ]])

                if err then
                    error("Failed to create embeddings_512 table: " .. err)
                end

                -- Create indexes for efficient querying
                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS idx_embeddings_origin ON embeddings_512(origin_id);
                ]])

                if err then
                    error("Failed to create origin_id index: " .. err)
                end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS idx_embeddings_content_type ON embeddings_512(content_type);
                ]])

                if err then
                    error("Failed to create content_type index: " .. err)
                end

                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS idx_embeddings_context ON embeddings_512(context_id);
                ]])

                if err then
                    error("Failed to create context_id index: " .. err)
                end

                -- Create index for vector similarity search
                success, err = db:execute([[
                    CREATE INDEX IF NOT EXISTS idx_embeddings_vector ON embeddings_512 USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
                ]])

                if err then
                    error("Failed to create vector index: " .. err)
                end

                return true
            end)

            down(function(db)
                -- Drop the table and indexes
                local success, err = db:execute([[
                    DROP TABLE IF EXISTS embeddings_512 CASCADE;
                ]])

                if err then
                    error("Failed to drop embeddings_512 table: " .. err)
                end

                -- We don't drop the vector extension as it might be used by other tables

                return true
            end)
        end)

        -- SQLite implementation using vec0
        database("sqlite", function()
            up(function(db)
                -- Create the embeddings_512 table using vec0 virtual table
                local success, err = db:execute([[
                    CREATE VIRTUAL TABLE IF NOT EXISTS embeddings_512 USING vec0(
                        entry_id TEXT PRIMARY KEY,
                        origin_id TEXT PARTITION KEY,      -- Partition key for efficient filtering
                        content_type TEXT,                 -- Metadata column for filtering
                        context_id TEXT,                   -- Metadata column for filtering
                        origin_id_aux TEXT,                -- Duplicate of origin_id for WHERE clause filtering (SQLite quirk)
                        +content TEXT,                     -- Auxiliary column (retrieval only)
                        +meta TEXT,                        -- Auxiliary column (retrieval only)
                        +created_at INTEGER default NOT NULL DEFAULT (datetime('now')),               -- Auxiliary column (retrieval only)
                        +updated_at INTEGER NOT NULL DEFAULT (datetime('now')),
                        embedding float[512]               -- Vector column for similarity search
                    )
                ]])

                if err then
                    error("Failed to create embeddings_512 table: " .. err)
                end

                -- Note: SQLite vec0 virtual tables don't support additional indexes
                -- The necessary indexing is handled internally by the vec0 implementation

                return true
            end)

            down(function(db)
                -- Drop the table and indexes
                local success, err = db:execute([[
                    DROP TABLE IF EXISTS embeddings_512;
                ]])

                if err then
                    error("Failed to drop embeddings_512 table: " .. err)
                end

                -- SQLite vec0 virtual tables don't support additional indexes
                -- No need to drop indexes in down migration

                return true
            end)
        end)
    end)
end)