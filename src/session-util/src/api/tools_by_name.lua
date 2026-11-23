local http = require("http")
local security = require("security")
local catalog_client = require("catalog_client")
local registry = require("registry")
local tools = require("tools")

-- Returns tool titles by the names that tool calls carry, for the Web Host
-- tool-call rows. tools.find_tools is not used: it runs the input schema
-- processors and the store cache for every tool and drops duplicate names.
local api = {
    _http = http,
    _security = security,
    _catalog_client = catalog_client,
    _registry = registry,
    _tools = tools,
}

-- Built-in rule. Tools are function entries of any kind (function.lua,
-- function.wasm and so on) with meta.type tool, the same filter that
-- wippy.agent.discovery:tools uses. A tool call carries the name the model
-- used: meta.llm_alias, or the sanitized id name when there is no alias. The
-- registry id also matches. A name that two tools share is left out, because
-- the call cannot say which tool ran; both registry ids still match. Private
-- tools are left out: Session does not show their calls.
local function registry_tools(): ({[string]: any}?, string?)
    local entries, err = api._registry.find({
        [".kind"] = "function.*",
        ["meta.type"] = "tool"
    })
    if err then
        return nil, tostring(err)
    end

    local by_id = {}
    local by_llm_name = {}
    local shared = {}
    for _, entry in ipairs(entries or {}) do
        local meta = entry.meta or {}
        if not meta.private then
            local llm_name = api._tools.get_tool_name(entry)
            local title = meta.title
            if not title or title == "" then
                title = llm_name
            end
            local found = { name = llm_name, title = title }
            if by_llm_name[llm_name] ~= nil then
                shared[llm_name] = true
            end
            by_llm_name[llm_name] = found
            by_id[entry.id] = found
        end
    end

    local by_name = {}
    for llm_name, found in pairs(by_llm_name) do
        if not shared[llm_name] then
            by_name[llm_name] = found
        end
    end
    for id, found in pairs(by_id) do
        by_name[id] = found
    end
    return by_name
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

    local tools_param = req:query("tools")
    if not tools_param or tools_param == "" then
        res:set_status(api._http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "Missing 'tools' query parameter. Expected a comma-separated list of tool names."
        })
        return
    end

    local names: {string} = {}
    for item in string.gmatch(tools_param, "[^,]+") do
        local name = item:match("^%s*(.-)%s*$")
        if name ~= "" then
            names[#names + 1] = name
        end
    end

    -- A failing catalog gives no tools rather than the built-in answer.
    local by_name = nil
    local catalog, catalog_err = api._catalog_client.open()
    if catalog then
        by_name = api._catalog_client.call(catalog, "tool_titles", { names = names })
    elseif not catalog_err then
        local lookup_err
        by_name, lookup_err = registry_tools()
        if lookup_err then
            res:set_status(api._http.STATUS.INTERNAL_ERROR)
            res:write_json({ success = false, error = "tool lookup failed" })
            return
        end
    end
    if type(by_name) ~= "table" then
        by_name = {}
    end

    -- Only requested names are copied, and each one is rebuilt as
    -- {name, title}, so a catalog's extra entries and extra fields never reach
    -- the answer, and the title is never empty. An empty result must still
    -- encode as {}.
    local result = table.create(0, 1)
    for _, name in ipairs(names) do
        local found = by_name[name]
        if type(found) == "table" then
            local tool_name = (type(found.name) == "string" and found.name ~= "") and found.name or name
            local title = (type(found.title) == "string" and found.title ~= "") and found.title or tool_name
            result[name] = { name = tool_name, title = title }
        end
    end

    res:set_status(api._http.STATUS.OK)
    res:write_json({
        success = true,
        tools = result
    })
end

api.handler = handler

return api
