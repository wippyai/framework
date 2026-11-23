local http = require("http")
local security = require("security")
local catalog_client = require("catalog_client")
local agent_registry = require("agent_registry")
local reader = require("reader")

-- Returns one agent's title and start prompts for the Web Host composer.
local api = {
    _http = http,
    _security = security,
    _catalog_client = catalog_client,
    _agent_registry = agent_registry,
    _session_reader = reader,
}

-- An unknown, hidden or non-agent reference gets the same answer, so the
-- response does not show whether a hidden agent exists. The json module has
-- no null value, so the body is written as text.
api.NO_AGENT_BODY = '{"success":true,"agent":null}'

-- Finds a gen1 agent the way the agent loader does: registry id first, then
-- meta.name. No visibility filter.
local function find_agent(identifier: string)
    local spec = api._agent_registry.get_by_id(identifier)
    if spec then
        return spec
    end
    return api._agent_registry.get_by_name(identifier)
end

-- The agent of a session the caller can read, when it is the requested one.
-- reader.open checks the actor and the session:<id> read permission and loads
-- the session for that user. The session's agent and the requested one match
-- by registry id, so a request by name finds a session stored by id and the
-- reverse. An agent_id that is not a registry agent never matches. Any failure
-- gives nil, so the answer never shows why.
local function session_agent(session_id: string?, identifier: string)
    if not session_id or session_id == "" then
        return nil
    end
    local session = api._session_reader.open(session_id)
    if not session then
        return nil
    end
    local session_agent_id = session:state().config.agent_id
    if type(session_agent_id) ~= "string" or session_agent_id == "" then
        return nil
    end
    local requested = find_agent(identifier)
    if not requested then
        return nil
    end
    local running = find_agent(session_agent_id)
    if not running or running.id ~= requested.id then
        return nil
    end
    return requested
end

-- Catalog first; the built-in rule hides meta.private agents. A catalog that
-- fails to open or to answer is an error, never a fallback to the built-in
-- rule.
local function lookup_agent(identifier: string)
    local catalog, catalog_err = api._catalog_client.open()
    if catalog_err then
        return nil, tostring(catalog_err)
    end
    if catalog then
        local spec, call_err = catalog:agent_details({ agent = identifier })
        if call_err then
            return nil, tostring(call_err)
        end
        return spec
    end
    local spec = find_agent(identifier)
    if spec and spec.meta.private then
        return nil
    end
    return spec
end

-- The runtime does not check a contract answer against its output schema, so
-- the handler checks the agent it is about to send. Returns what is wrong, or
-- nil. An empty name or title is allowed: the answer falls back to the id or
-- the name.
local function invalid_agent(spec): string?
    if type(spec) ~= "table" or type(spec.id) ~= "string" or spec.id == "" then
        return "the agent has no string id"
    end
    if spec.name ~= nil and type(spec.name) ~= "string" then
        return "the agent name is not a string"
    end
    if spec.title ~= nil and type(spec.title) ~= "string" then
        return "the agent title is not a string"
    end
    if spec.start_prompts ~= nil then
        if type(spec.start_prompts) ~= "table" then
            return "start_prompts is not a list"
        end
        local count = 0
        for _, item in pairs(spec.start_prompts) do
            count = count + 1
            if type(item) ~= "string" then
                return "start_prompts holds a value that is not a string"
            end
        end
        if count ~= #spec.start_prompts then
            return "start_prompts is not a list"
        end
    end
    return nil
end

local function fail(res, message: string)
    res:set_status(api._http.STATUS.INTERNAL_ERROR)
    res:write_json({ success = false, error = message })
end

local function handler()
    local res = api._http.response()
    local req = api._http.request()
    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    res:set_content_type(api._http.CONTENT.JSON)
    res:set_header("Cache-Control", "no-store")

    if not api._security.actor() then
        res:set_status(api._http.STATUS.UNAUTHORIZED)
        res:write_json({
            success = false,
            error = "Authentication required"
        })
        return
    end

    local agent_param = req:query("agent")
    if not agent_param or agent_param == "" then
        res:set_status(api._http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "Missing 'agent' query parameter"
        })
        return
    end

    -- The normal lookup runs first, so a bound catalog's answer wins for an
    -- agent that the caller may see. Session access only adds an agent that
    -- the lookup hides.
    local spec, lookup_err = lookup_agent(agent_param)
    if lookup_err then
        fail(res, "agent lookup failed: " .. lookup_err)
        return
    end
    if spec == nil then
        spec = session_agent(req:query("session_id"), agent_param)
    end
    if spec == nil then
        res:set_status(api._http.STATUS.OK)
        res:write(api.NO_AGENT_BODY)
        return
    end
    local invalid = invalid_agent(spec)
    if invalid then
        fail(res, "invalid agent for '" .. agent_param .. "': " .. invalid)
        return
    end

    -- An agent without meta.name (for example one found by registry id) is
    -- named by its id, so the name and the title fallback are never empty.
    local name = (spec.name ~= nil and spec.name ~= "") and spec.name or spec.id
    res:set_status(api._http.STATUS.OK)
    res:write_json({
        success = true,
        agent = {
            id = spec.id,
            name = name,
            title = (spec.title ~= nil and spec.title ~= "") and spec.title or name,
            start_prompts = spec.start_prompts or {}
        }
    })
end

api.handler = handler

return api
