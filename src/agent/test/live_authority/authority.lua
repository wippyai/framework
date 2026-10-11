local sql = require("sql")
local security = require("security")
local M = {}

local function credential(subject_id, credential_id)
    local db = assert(sql.get("app.agent_authority:db"))
    local rows, err = db:query([[SELECT credential_id, token FROM agent_authority_subjects
        WHERE subject_id = $1 AND ($2 = '' OR credential_id = $2)]], {subject_id, credential_id or ""})
    db:release()
    if err then error(err) end
    if #rows ~= 1 or type(rows[1].token) ~= "string" then error("execution credential is unavailable") end
    return rows[1]
end

function M.capture(actor, scope)
    local stored = credential(actor:id(), nil)
    return {credential_id = stored.credential_id}, nil
end

function M.resolve(args)
    assert(args.authority_only == true)
    local stored = credential(args.subject_id, args.authority_context.credential_id)
    local tokens = assert(security.token_store("app.agent_authority:tokens"))
    return tokens:validate(stored.token)
end

return M
