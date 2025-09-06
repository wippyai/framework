return require("migration").define(function()
    migration("Create dataflows table", function()
        database("postgres", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE dataflows (
                        dataflow_id UUID PRIMARY KEY,
                        parent_dataflow_id UUID,
                        actor_id TEXT NOT NULL,
                        type TEXT NOT NULL,
                        status TEXT DEFAULT 'pending',
                        last_commit_id UUID,
                        metadata JSONB DEFAULT '{}',
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        updated_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (parent_dataflow_id) REFERENCES dataflows(dataflow_id) ON DELETE CASCADE
                    )
                ]])

                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_type ON dataflows(type)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_status ON dataflows(status)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_parent ON dataflows(parent_dataflow_id) WHERE parent_dataflow_id IS NOT NULL")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_actor_id ON dataflows(actor_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_last_commit ON dataflows(last_commit_id) WHERE last_commit_id IS NOT NULL")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_last_commit")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_type")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_status")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_parent")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_actor_id")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP TABLE IF EXISTS dataflows")
                if err then
                    error(err)
                end
            end)
        end)

        database("sqlite", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE dataflows (
                        dataflow_id TEXT PRIMARY KEY,
                        parent_dataflow_id TEXT,
                        actor_id TEXT NOT NULL,
                        type TEXT NOT NULL,
                        status TEXT DEFAULT 'pending',
                        last_commit_id TEXT,
                        metadata TEXT DEFAULT '{}',
                        created_at INTEGER NOT NULL,
                        updated_at INTEGER NOT NULL,
                        FOREIGN KEY (parent_dataflow_id) REFERENCES dataflows(dataflow_id) ON DELETE CASCADE
                    )
                ]])

                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_type ON dataflows(type)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_status ON dataflows(status)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_parent ON dataflows(parent_dataflow_id) WHERE parent_dataflow_id IS NOT NULL")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_actor_id ON dataflows(actor_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflows_last_commit ON dataflows(last_commit_id) WHERE last_commit_id IS NOT NULL")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_last_commit")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_type")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_status")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_parent")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflows_actor_id")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP TABLE IF EXISTS dataflows")
                if err then
                    error(err)
                end
            end)
        end)
    end)
end)