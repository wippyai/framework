return require("migration").define(function()
    migration("Create nodes table", function()
        database("postgres", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE nodes (
                        node_id UUID PRIMARY KEY,
                        dataflow_id UUID NOT NULL,
                        parent_node_id UUID,
                        type TEXT NOT NULL,
                        status TEXT DEFAULT 'pending',
                        config JSONB DEFAULT '{}',
                        metadata JSONB DEFAULT '{}',
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        updated_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (dataflow_id) REFERENCES dataflows(dataflow_id) ON DELETE CASCADE,
                        FOREIGN KEY (parent_node_id) REFERENCES nodes(node_id) ON DELETE CASCADE
                    )
                ]])

                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_nodes_dataflow ON nodes(dataflow_id)")
                if err then
                    error(err)
                end

                success, err = db:execute(
                "CREATE INDEX idx_nodes_parent ON nodes(parent_node_id) WHERE parent_node_id IS NOT NULL")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_nodes_status ON nodes(status)")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_nodes_dataflow")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_nodes_parent")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_nodes_status")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP TABLE IF EXISTS nodes")
                if err then
                    error(err)
                end
            end)
        end)

        database("sqlite", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE nodes (
                        node_id TEXT PRIMARY KEY,
                        dataflow_id TEXT NOT NULL,
                        parent_node_id TEXT,
                        type TEXT NOT NULL,
                        status TEXT DEFAULT 'pending',
                        config TEXT DEFAULT '{}',
                        metadata TEXT DEFAULT '{}',
                        created_at INTEGER NOT NULL,
                        updated_at INTEGER NOT NULL,
                        FOREIGN KEY (dataflow_id) REFERENCES dataflows(dataflow_id) ON DELETE CASCADE,
                        FOREIGN KEY (parent_node_id) REFERENCES nodes(node_id) ON DELETE CASCADE
                    )
                ]])

                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_nodes_dataflow ON nodes(dataflow_id)")
                if err then
                    error(err)
                end

                success, err = db:execute(
                "CREATE INDEX idx_nodes_parent ON nodes(parent_node_id) WHERE parent_node_id IS NOT NULL")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_nodes_status ON nodes(status)")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_nodes_dataflow")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_nodes_parent")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_nodes_status")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP TABLE IF EXISTS nodes")
                if err then
                    error(err)
                end
            end)
        end)
    end)
end)
