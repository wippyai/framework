local sql = require("sql")
local security = require("security")
local M = {}

local function credential(subject_id, credential_id)
    local db, db_err = sql.get("app.agent_authority:db")
    if db_err then return nil, db_err end
    local rows, err = db:query([[SELECT credential_id, token, provider_available FROM agent_authority_subjects
        WHERE subject_id = $1 AND ($2 = '' OR credential_id = $2)]], {subject_id, credential_id or ""})
    db:release()
    if err then return nil, err end
    if #rows ~= 1 or type(rows[1].token) ~= "string" then
        return nil, errors.new({message = "Execution credential is unavailable", kind = errors.UNAVAILABLE, retryable = true})
    end
    if rows[1].provider_available ~= 1 then
        return nil, errors.new({message = "Authority provider is unavailable", kind = errors.UNAVAILABLE, retryable = true})
    end
    return rows[1]
end

function M.capture(actor, scope)
    local stored, err = credential(actor:id(), nil)
    if err then return nil, err end
    return {credential_id = stored.credential_id}, nil
end

function M.resolve(args)
    if args.authority_only ~= true then
        return nil, nil, errors.new({message = "Authority-only resolution is required", kind = errors.INVALID, retryable = false})
    end
    local stored, err = credential(args.subject_id, args.authority_context.credential_id)
    if err then return nil, nil, err end
    local tokens, tokens_err = security.token_store("app.agent_authority:tokens")
    if tokens_err then return nil, nil, tokens_err end
    return tokens:validate(stored.token)
end

return M
