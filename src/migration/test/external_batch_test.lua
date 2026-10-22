local test = require("test")
local sql = require("sql")
local env = require("env")
local uuid = require("uuid")
local migration_api = require("migration_api")
local repository = require("repository")

local function checked(value: any, err: any): any
    if err then error(err) end
    return value
end

local function definition(dialect: string, page: any, hook: any?): any
    return function()
        migration("External idempotent repair", function()
            database(dialect, function()
                up(page, "external_batch")
                if hook then after(hook) end
                down(function() end)
            end)
        end)
    end
end

local function fixture(database_id: string, fn: any): ()
    local db = assert(sql.get(database_id))
    local dialect = checked(db:type())
    local observer_id = dialect == sql.type.POSTGRES and "app:concurrent_pg_b" or "app:concurrent_sqlite_b"
    local observer = assert(sql.get(observer_id))
    local id = "app:external:" .. uuid.v7()
    checked(repository.init_tracking_table(db))
    checked(db:execute("CREATE TABLE IF NOT EXISTS external_batch_work (id VARCHAR(512) PRIMARY KEY, value INTEGER NOT NULL)"))
    checked(db:execute("INSERT INTO external_batch_work (id,value) VALUES ($1,0)", {id}))
    local ok, err = pcall(fn, db, observer, dialect, id)
    checked(db:execute("DELETE FROM external_batch_work WHERE id=$1", {id}))
    checked(db:execute("DELETE FROM _migrations WHERE id=$1", {id}))
    local progress = checked(repository.init_progress_table(db, dialect))
    checked(repository.remove_progress(db, progress, {id}))
    observer:release()
    db:release()
    if not ok then error(err) end
end

local function define_tests(): ()
    local databases = {"app:concurrent_sqlite_a"}
    if env.get("app:enable_postgres") == "true" then databases[#databases + 1] = "app:concurrent_pg_a" end
    for _, database_id in ipairs(databases) do
        test.describe("External batches on " .. database_id, function()
            test.it("lets a distinct resource for the same database commit during the callback", function()
                fixture(database_id, function(db, observer, dialect, id)
                    local calls = 0
                    local result = migration_api.run(definition(dialect, function(connection, cursor)
                        calls = calls + 1
                        test.eq(connection, db)
                        if calls == 1 then test.is_nil(cursor) else test.eq(cursor, "page-1") end
                        checked(observer:execute("UPDATE external_batch_work SET value=value+1 WHERE id=$1", {id}))
                        return calls == 1 and "page-1" or nil
                    end), {db=db,id=id})
                    test.eq(result.status, "complete", tostring(result.error))
                    test.eq(result.applied, 1)
                    test.eq(calls, 2)
                    test.eq(checked(db:query("SELECT value FROM external_batch_work WHERE id=$1", {id}))[1].value, 2)
                end)
            end)

            test.it("replays committed caller work after a final action fails without marking applied", function()
                fixture(database_id, function(db, observer, dialect, id)
                    local fail = true
                    local run = definition(dialect, function()
                        checked(observer:execute("UPDATE external_batch_work SET value=1 WHERE id=$1", {id}))
                        if fail then error("notification failed") end
                    end)
                    local first = migration_api.run(run, {db=db,id=id})
                    test.eq(first.status, "error")
                    test.is_false(checked(repository.is_applied(db, id)))
                    fail = false
                    test.eq(migration_api.run(run, {db=db,id=id}).status, "complete")
                    test.eq(checked(db:query("SELECT value FROM external_batch_work WHERE id=$1", {id}))[1].value, 1)
                    test.eq(migration_api.run(run, {db=db,id=id}).skipped, 1)
                end)
            end)

            test.it("discards a stale checkpoint after an interleaved runner advances", function()
                fixture(database_id, function(db, observer, dialect, id)
                    local observed = {}
                    local peer = definition(dialect, function(_, cursor)
                        if cursor == nil then return "peer-progress" end
                        error("peer interrupted after its checkpoint")
                    end)
                    local outer = definition(dialect, function(_, cursor)
                        observed[#observed+1] = cursor or "start"
                        if cursor == nil then
                            test.eq(migration_api.run(peer, {db=observer,id=id}).status, "error")
                            return "stale-progress"
                        end
                        test.eq(cursor, "peer-progress")
                    end)
                    local result = migration_api.run(outer, {db=db,id=id})
                    test.eq(result.status, "complete", tostring(result.error))
                    test.eq(#observed, 2)
                    test.eq(observed[2], "peer-progress")
                end)
            end)

            test.it("skips completion won by an interleaved runner", function()
                fixture(database_id, function(db, observer, dialect, id)
                    local result = migration_api.run(definition(dialect, function()
                        test.eq(migration_api.run(definition(dialect, function() end), {db=observer,id=id}).status, "complete")
                        return "stale-progress"
                    end), {db=db,id=id})
                    test.eq(result.status, "complete", tostring(result.error))
                    test.eq(result.skipped, 1)
                end)
            end)

            test.it("rejects forced replay of an applied external batch before caller work", function()
                fixture(database_id, function(db, _, dialect, id)
                    checked(repository.record_migration(db, id, "already repaired"))
                    local calls = 0
                    local result = migration_api.run(definition(dialect, function() calls=calls+1 end), {db=db,id=id,force=true})
                    test.eq(result.failed, 1)
                    test.eq(calls, 0)
                end)
            end)

            test.it("rejects non-advancing checkpoints and leaves committed work replayable", function()
                fixture(database_id, function(db, observer, dialect, id)
                    local calls = 0
                    local result = migration_api.run(definition(dialect, function()
                        calls=calls+1
                        checked(observer:execute("UPDATE external_batch_work SET value=1 WHERE id=$1", {id}))
                        return "same"
                    end), {db=db,id=id})
                    test.eq(result.status, "error")
                    test.eq(calls, 2)
                    test.is_false(checked(repository.is_applied(db, id)))
                end)
            end)

            test.it("bounds transient contention and never calls work before the ledger snapshot commits", function()
                fixture(database_id, function(db, _, dialect, id)
                    local begins, calls = 0, 0
                    local adapter = {type=function() return db:type() end,
                        query=function(_,q,p) return db:query(q,p) end,
                        execute=function(_,q,p) return db:execute(q,p) end,
                        begin=function()
                            begins=begins+1
                            return nil, "database is locked"
                        end}
                    local result = migration_api.run(definition(dialect, function() calls=calls+1 end), {db=adapter,id=id})
                    test.eq(result.status, "error")
                    test.eq(begins, dialect == sql.type.SQLITE and 5 or 1)
                    test.eq(calls, 0)
                end)
            end)

            test.it("does not mark completion when the checkpoint commit fails", function()
                fixture(database_id, function(db, observer, dialect, id)
                    local begins = 0
                    local adapter = {type=function() return db:type() end,
                        query=function(_,q,p) return db:query(q,p) end,
                        execute=function(_,q,p) return db:execute(q,p) end,
                        begin=function(_,options)
                            begins=begins+1
                            local tx,err=db:begin(options)
                            if err or begins~=2 then return tx,err end
                            return {query=function(_,q,p) return tx:query(q,p) end,
                                execute=function(_,q,p) return tx:execute(q,p) end,
                                rollback=function() return tx:rollback() end,
                                commit=function() return nil,"injected checkpoint commit failure" end}
                        end}
                    local run=definition(dialect,function()
                        checked(observer:execute("UPDATE external_batch_work SET value=1 WHERE id=$1",{id}))
                    end)
                    local first=migration_api.run(run,{db=adapter,id=id})
                    test.eq(first.status,"error")
                    test.is_false(checked(repository.is_applied(db,id)))
                    test.eq(migration_api.run(run,{db=db,id=id}).status,"complete")
                end)
            end)

            test.it("resumes an alias checkpoint and honors its applied marker", function()
                fixture(database_id, function(db, _, dialect, id)
                    local alias=id..":alias"
                    local progress=checked(repository.init_progress_table(db,dialect))
                    checked(repository.record_progress(db,progress,alias,"saved"))
                    local calls=0
                    local run=definition(dialect,function(_,cursor)
                        test.eq(cursor,"saved")
                        calls=calls+1
                    end)
                    local first=migration_api.run(run,{db=db,id=id,aliases={alias}})
                    test.eq(first.status,"complete",tostring(first.error))
                    test.eq(calls,1)
                    test.eq(#checked(db:query("SELECT id FROM "..progress.." WHERE id=$1",{alias})),0)
                    checked(repository.remove_migration(db,id))
                    checked(repository.record_migration(db,alias,"old identity"))
                    test.eq(migration_api.run(run,{db=db,id=id,aliases={alias}}).skipped,1)
                    test.eq(calls,1)
                    checked(repository.remove_migration(db,alias))
                end)
            end)

            test.it("keeps after hooks inside the final ledger transaction", function()
                fixture(database_id, function(db, observer, dialect, id)
                    local hooks = 0
                    local run = definition(dialect, function()
                        checked(observer:execute("UPDATE external_batch_work SET value=1 WHERE id=$1", {id}))
                    end, function(tx)
                        hooks=hooks+1
                        checked(tx:execute("UPDATE external_batch_work SET value=2 WHERE id=$1", {id}))
                        error("hook failed")
                    end)
                    test.eq(migration_api.run(run, {db=db,id=id}).status, "error")
                    test.eq(hooks, 1)
                    test.eq(checked(db:query("SELECT value FROM external_batch_work WHERE id=$1", {id}))[1].value, 1)
                    test.is_false(checked(repository.is_applied(db, id)))
                end)
            end)
        end)
    end
end

return test.run_cases(define_tests)
