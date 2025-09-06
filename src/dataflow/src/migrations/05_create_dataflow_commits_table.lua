return require("migration").define(function()
    migration("Create dataflow commits table for outbox pattern", function()
        database("postgres", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE dataflow_commits (
                        commit_id UUID PRIMARY KEY,
                        dataflow_id UUID NOT NULL,
                        execution_id UUID,
                        op_id UUID,
                        payload JSONB NOT NULL,
                        metadata JSONB DEFAULT '{}',
                        created_at TIMESTAMP NOT NULL DEFAULT now(),
                        FOREIGN KEY (dataflow_id) REFERENCES dataflows(dataflow_id) ON DELETE CASCADE,
                        FOREIGN KEY (execution_id) REFERENCES node_executions(execution_id) ON DELETE SET NULL
                    )
                ]])

                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflow_commits_dataflow ON dataflow_commits(dataflow_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflow_commits_execution_id ON dataflow_commits(execution_id) WHERE execution_id IS NOT NULL")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflow_commits_op_id ON dataflow_commits(op_id) WHERE op_id IS NOT NULL")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_dataflow_commits_op_id")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflow_commits_execution_id")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflow_commits_dataflow")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP TABLE IF EXISTS dataflow_commits")
                if err then
                    error(err)
                end
            end)
        end)

        database("sqlite", function()
            up(function(db)
                local success, err = db:execute([[
                    CREATE TABLE dataflow_commits (
                        commit_id TEXT PRIMARY KEY,
                        dataflow_id TEXT NOT NULL,
                        execution_id TEXT,
                        op_id TEXT,
                        payload TEXT NOT NULL,
                        metadata TEXT DEFAULT '{}',
                        created_at INTEGER NOT NULL,
                        FOREIGN KEY (dataflow_id) REFERENCES dataflows(dataflow_id) ON DELETE CASCADE,
                        FOREIGN KEY (execution_id) REFERENCES node_executions(execution_id) ON DELETE SET NULL
                    )
                ]])

                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflow_commits_dataflow ON dataflow_commits(dataflow_id)")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflow_commits_execution_id ON dataflow_commits(execution_id) WHERE execution_id IS NOT NULL")
                if err then
                    error(err)
                end

                success, err = db:execute("CREATE INDEX idx_dataflow_commits_op_id ON dataflow_commits(op_id) WHERE op_id IS NOT NULL")
                if err then
                    error(err)
                end
            end)

            down(function(db)
                local success, err = db:execute("DROP INDEX IF EXISTS idx_dataflow_commits_op_id")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflow_commits_execution_id")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP INDEX IF EXISTS idx_dataflow_commits_dataflow")
                if err then
                    error(err)
                end

                success, err = db:execute("DROP TABLE IF EXISTS dataflow_commits")
                if err then
                    error(err)
                end
            end)
        end)
    end)
end)