local sql = require("sql")
local json = require("json")
local security = require("security")
local funcs = require("funcs")
local tool_caller = require("tool_caller")
local M = {}

function M.lookup(args)
    local db = assert(sql.get("app.agent_authority:db"))
    local rows, err = db:query("SELECT groups_json, active FROM agent_authority_subjects WHERE subject_id = $1", {args.subject_id})
    db:release()
    if err then error(err) end
    if #rows ~= 1 or rows[1].active ~= 1 then
        return {success = false, error = {kind = "PermissionDenied", message = "subject is inactive"}}
    end
    return {subject_id = args.subject_id, groups = assert(json.decode(rows[1].groups_json)),
        meta = args.actor_meta or {}, ceiling = args.actor_meta and args.actor_meta.ceiling or nil}
end

function M.mutate(args)
    local db = assert(sql.get("app.agent_authority:db"))
    local _, err
    if args.mode == "group_reduction" then
        _, err = db:execute("UPDATE agent_authority_subjects SET groups_json = $1 WHERE subject_id = $2",
            {assert(json.encode({"app.agent_authority:member"})), args.subject_id})
    elseif args.mode == "disabled" then
        _, err = db:execute("UPDATE agent_authority_subjects SET active = 0 WHERE subject_id = $1", {args.subject_id})
    elseif args.mode == "unavailable" then
        _, err = db:execute("UPDATE agent_authority_subjects SET provider_available = 0 WHERE subject_id = $1", {args.subject_id})
    elseif args.mode == "revoked" then
        local tokens = assert(security.token_store("app.agent_authority:tokens"))
        local rows = assert(db:query("SELECT token FROM agent_authority_subjects WHERE subject_id = $1", {args.subject_id}))
        local ok
        ok, err = tokens:revoke(rows[1].token)
        if not err then assert(ok) end
    end
    db:release()
    if err then error(err) end
    return true
end

function M.effect()
    local actor = assert(security.actor())
    local db = assert(sql.get("app.agent_authority:db"))
    local _, err = db:execute("UPDATE agent_authority_subjects SET effects = effects + 1 WHERE subject_id = $1", {actor:id()})
    db:release()
    if err then error(err) end
    return {subject_id = actor:id()}
end

function M.run(args)
    require("execution_authority").refresh_perms = true
    local caller = tool_caller.new():set_strategy(args.strategy)
    local actor = assert(security.actor())
    local changed, err = funcs.call("app.agent_authority:mutate", {subject_id = actor:id(), mode = args.mode})
    if err then error(err) end
    assert(changed)
    local result = caller:execute({}, {effect = {call_id = "effect", name = "protected_effect",
        registry_id = "app.agent_authority:protected_effect", args = {}, valid = true}})
    return result.effect
end

return M
