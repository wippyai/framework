local test = require("test")
local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local security = require("security")
local funcs = require("funcs")

local function run_tests()
    test.describe("UPSTREAM-AGENT-TOOL-LIVE-AUTHORITY", function()
        local db
        local tokens
        test.before_all(function()
            db = assert(sql.get("app.agent_authority:db"))
            tokens = assert(security.token_store("app.agent_authority:tokens"))
            local _, err = db:execute([[CREATE TABLE agent_authority_subjects (
                subject_id TEXT PRIMARY KEY, groups_json TEXT NOT NULL, active INTEGER NOT NULL,
                effects INTEGER NOT NULL DEFAULT 0, credential_id TEXT UNIQUE, token TEXT)]])
            test.is_nil(err)
        end)
        test.after_all(function() db:release() end)

        for _, strategy in ipairs({"sequential", "parallel"}) do
            for _, mode in ipairs({"group_reduction", "disabled", "revoked", "unavailable", "unchanged", "ceiling"}) do
                test.it(strategy .. " resolves current authority before dispatch: " .. mode, function()
                    local subject_id = uuid.v7()
                    local _, err = db:execute([[INSERT INTO agent_authority_subjects
                        (subject_id, groups_json, active, credential_id) VALUES ($1, $2, 1, $1)]],
                        {subject_id, assert(json.encode({"app.agent_authority:member", "app.agent_authority:privileged"}))})
                    test.is_nil(err)
                    local meta = mode == "ceiling" and {ceiling = {groups = {"app.agent_authority:member"}}} or {}
                    local issued_actor = assert(security.new_actor(subject_id, meta))
                    local issued_scope = assert(security.named_scope("app.agent_authority:privileged"))
                    local token, token_err = tokens:create(issued_actor, issued_scope)
                    test.is_nil(token_err)
                    local _, store_err = db:execute("UPDATE agent_authority_subjects SET token = $1 WHERE subject_id = $2", {token, subject_id})
                    test.is_nil(store_err)
                    local actor, scope, live_err = tokens:validate(token)
                    test.is_nil(live_err)
                    test.eq(scope:evaluate(actor, "funcs.call", "app.agent_authority:protected_effect"),
                        mode == "ceiling" and "undefined" or "allow")
                    local result, exec_err = funcs.new():with_actor(actor):with_scope(scope)
                        :call("app.agent_authority:worker", {strategy = strategy, mode = mode})
                    test.is_nil(exec_err)
                    local rows = assert(db:query("SELECT effects FROM agent_authority_subjects WHERE subject_id = $1", {subject_id}))
                    test.eq(rows[1].effects, mode == "unchanged" and 1 or 0,
                        "current authority and credential ceiling govern the next tool effect")
                    if mode == "unchanged" then
                        test.is_nil(result.error)
                        test.eq(result.result.subject_id, subject_id)
                    else
                        test.not_nil(result.error)
                        test.is_nil(result.result)
                        if mode == "unavailable" then
                            test.is_true(errors.is(result.error, errors.UNAVAILABLE))
                            test.is_true(result.error:retryable())
                        end
                    end
                end)
            end
        end
    end)
end

return {run_tests = test.run_cases(run_tests)}
