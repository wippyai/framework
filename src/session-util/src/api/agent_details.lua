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
-- the session for that user. Any failure gives nil, so the answer never shows
-- why.
local function session_agent(session_id: string?, identifier: string)
    if not session_id or session_id == "" then
        return nil
    end
    local session = api._session_reader.open(session_id)
    if not session then
        return nil
    end
    if session:state().config.agent_id ~= identifier then
        return nil
    end
    return find_agent(identifier)
end

-- Catalog first; the built-in rule hides meta.private agents. A failing
-- catalog gives no agent.
local function lookup_agent(identifier: string)
    local catalog, catalog_err = api._catalog_client.open()
    if catalog_err then
        return nil
    end
    if catalog then
        return catalog:agent_details({ agent = identifier })
    end
    local spec = find_agent(identifier)
    if spec and spec.meta.private then
        return nil
    end
    return spec
end

-- The Web Host renders start prompts as text, so only strings are returned.
-- A start_prompts value that is not a list gives no prompts.
local function start_prompts_of(spec): {string}
    local prompts: {string} = {}
    if type(spec.start_prompts) ~= "table" then
        return prompts
    end
    for _, item in ipairs(spec.start_prompts) do
        if type(item) == "string" then
            prompts[#prompts + 1] = item
        end
    end
    return prompts
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

    local spec = session_agent(req:query("session_id"), agent_param)
    if not spec then
        spec = lookup_agent(agent_param)
    end
    if type(spec) ~= "table" then
        res:set_status(api._http.STATUS.OK)
        res:write(api.NO_AGENT_BODY)
        return
    end

    res:set_status(api._http.STATUS.OK)
    res:write_json({
        success = true,
        agent = {
            id = spec.id,
            name = spec.name,
            title = (spec.title ~= nil and spec.title ~= "") and spec.title or spec.name,
            start_prompts = start_prompts_of(spec)
        }
    })
end

api.handler = handler

return api
