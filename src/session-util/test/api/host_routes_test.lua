local test = require("test")
local http = require("http")
local json = require("json")
local registry = require("registry")
local security = require("security")
local funcs = require("funcs")
local contract = require("contract")
local agent_details = require("agent_details")
local tools_by_name = require("tools_by_name")
local catalog_client = require("catalog_client")

-- GET /agents/details and GET /tools/by-name against the registry fixtures in
-- test/api/_index.yaml. The HTTP context and the actor are faked everywhere.
-- The catalog contract and the session reader are the real ones unless a
-- test installs a fake: the test app binds no catalog, so the real contract
-- module gives the built-in rules.

local TEST_ROUTER = "app:api"

-- Installs a fake request and response on a handler module. `raw` holds the
-- body as it goes on the wire: the text of res:write, or the JSON encoding of
-- the value given to res:write_json.
local function install(api, query: {[string]: string}, authenticated: boolean?): any
    local result: any = { headers = {} }
    local req = {
        query = function(_, key) return query[key] end,
    }
    local res = {
        set_content_type = function(_, value) result.content_type = value end,
        set_header = function(_, key, value) result.headers[key] = value end,
        set_status = function(_, value) result.status = value end,
        write = function(_, value) result.raw = value end,
        write_json = function(_, value)
            result.body = value
            result.raw = json.encode(value)
        end,
    }
    api._http = {
        STATUS = http.STATUS,
        CONTENT = http.CONTENT,
        request = function() return req end,
        response = function() return res end,
    }
    api._security = {
        actor = function()
            if authenticated == false then return nil end
            return { id = function() return "actor-host-routes" end }
        end,
    }
    return result
end

-- A fake contract module. `implementation` is what :open() returns; nil means
-- no application binds the catalog. `implementations_err` makes
-- :implementations() fail, and `get_err` makes contract.get fail. `calls`
-- counts what the handler did.
local function fake_contract(implementation: any?, open_err: string?, implementations_err: string?, get_err: string?): (any, any)
    local calls: any = { get = {}, open = 0 }
    local module = {
        get = function(id)
            calls.get[#calls.get + 1] = id
            if get_err then return nil, get_err end
            return {
                implementations = function(_)
                    if implementations_err then return nil, implementations_err end
                    if implementation == nil then return {} end
                    return { "app.api:fake_catalog_binding" }
                end,
                open = function(_)
                    calls.open = calls.open + 1
                    if open_err then return nil, open_err end
                    return implementation
                end,
            }
        end,
    }
    return module, calls
end

-- A fake session reader. `sessions` maps a session id to its agent_id; any
-- other id fails to open. `calls.open` lists the ids the handler opened.
local function fake_reader(sessions: {[string]: string}): (any, any)
    local calls: any = { open = {} }
    local reader = {
        open = function(session_id)
            calls.open[#calls.open + 1] = session_id
            local agent_id = sessions[session_id]
            if not agent_id then
                return nil, "Session not found"
            end
            return {
                state = function(_)
                    return { config = { agent_id = agent_id } }
                end,
            }
        end,
    }
    return reader, calls
end

-- A fake registry for the tool lookup. find keeps the entries whose kind
-- matches the query's .kind, where a trailing ".*" matches any suffix, and
-- whose meta.type equals the query's meta.type.
local function fake_registry(entries: {any}): any
    return {
        find = function(query)
            local kind = tostring(query[".kind"])
            local found = {}
            for _, entry in ipairs(entries) do
                local kind_matches = entry.kind == kind
                if kind:sub(-2) == ".*" then
                    local prefix = kind:sub(1, -2)
                    kind_matches = entry.kind:sub(1, #prefix) == prefix
                end
                if kind_matches and entry.meta.type == query["meta.type"] then
                    found[#found + 1] = entry
                end
            end
            return found
        end,
    }
end

local function count_keys(map: any): number
    local count = 0
    for _ in pairs(map) do count = count + 1 end
    return count
end

local function define_tests()
    describe("Web Host route registration", function()
        it("registers the exact GET paths the Web Host calls, each on its own handler", function()
            local expected = {
                ["wippy.session_util.api:agent_details.endpoint"] = { path = "/agents/details", func = "agent_details" },
                ["wippy.session_util.api:tools_by_name.endpoint"] = { path = "/tools/by-name", func = "tools_by_name" },
            }
            for id, want in pairs(expected) do
                local entry, err = registry.get(id)
                test.is_nil(err)
                test.eq(entry.kind, "http.endpoint")
                test.eq(entry.data.method, "GET")
                test.eq(entry.data.path, want.path)
                local func = tostring(entry.data.func)
                test.eq(func:sub(-#want.func), want.func)
            end
        end)

        it("puts both functions and both endpoints on the router the test app binds to api_router", function()
            for _, id in ipairs({
                "wippy.session_util.api:agent_details",
                "wippy.session_util.api:agent_details.endpoint",
                "wippy.session_util.api:tools_by_name",
                "wippy.session_util.api:tools_by_name.endpoint",
            }) do
                local entry, err = registry.get(id)
                test.is_nil(err)
                test.eq(entry.meta.router, TEST_ROUTER)
            end
        end)

        it("gives neither handler a security block, so both run as the caller", function()
            -- A function entry keeps its security block in entry.data.security.
            for _, id in ipairs({
                "wippy.session_util.api:agent_details",
                "wippy.session_util.api:tools_by_name",
            }) do
                local entry, err = registry.get(id)
                test.is_nil(err)
                test.eq(entry.kind, "function.lua")
                test.not_nil(entry.data)
                test.is_nil(entry.data.security)
            end
        end)
    end)

    describe("GET /agents/details", function()
        local original = {
            http = agent_details._http,
            security = agent_details._security,
            contract = catalog_client._contract,
            reader = agent_details._session_reader,
        }

        after_each(function()
            agent_details._http = original.http
            agent_details._security = original.security
            catalog_client._contract = original.contract
            agent_details._session_reader = original.reader
        end)

        it("returns a public agent by name with its start prompts", function()
            local result = install(agent_details, { agent = "host-routes-public" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.content_type, http.CONTENT.JSON)
            test.eq(result.headers["Cache-Control"], "no-store")
            test.is_true(result.body.success)
            local agent = result.body.agent
            test.eq(agent.id, "app.api:host_routes_public_agent")
            test.eq(agent.name, "host-routes-public")
            test.eq(agent.title, "Host Routes Helper")
            test.eq(#agent.start_prompts, 2)
            test.eq(agent.start_prompts[1], "Summarize this page")
            test.eq(agent.start_prompts[2], "Draft a reply")
        end)

        it("returns an agent by registry id and uses its name when it has no title", function()
            -- host_routes_shadow_agent has this id as its meta.name; the id lookup must win.
            local result = install(agent_details, { agent = "app.api:host_routes_untitled_agent" })
            agent_details.handler()
            test.eq(result.status, 200)
            local agent = result.body.agent
            test.eq(agent.id, "app.api:host_routes_untitled_agent")
            test.eq(agent.name, "host-routes-untitled")
            test.eq(agent.title, "host-routes-untitled")
            test.eq(#agent.start_prompts, 0)
        end)

        it("names an agent without meta.name by its registry id", function()
            local result = install(agent_details, { agent = "app.api:host_routes_nameless_agent" })
            agent_details.handler()
            test.eq(result.status, 200)
            local agent = result.body.agent
            test.eq(agent.id, "app.api:host_routes_nameless_agent")
            test.eq(agent.name, "app.api:host_routes_nameless_agent")
            test.eq(agent.title, "app.api:host_routes_nameless_agent")
        end)

        it("finds an agent by a name that contains a colon", function()
            local result = install(agent_details, { agent = "host-routes:colon" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.body.agent.id, "app.api:host_routes_colon_name_agent")
            test.eq(result.body.agent.title, "Colon Name Helper")
        end)

        it("answers 500 for an agent whose start_prompts is not a list of strings", function()
            local scalar = install(agent_details, { agent = "host-routes-scalar-prompts" })
            agent_details.handler()
            test.eq(scalar.status, 500)
            test.eq(scalar.headers["Cache-Control"], "no-store")
            test.is_false(scalar.body.success)
            test.not_nil((string.find(scalar.body.error, "start_prompts is not a list", 1, true)))

            local object = install(agent_details, { agent = "host-routes-object-prompts" })
            agent_details.handler()
            test.eq(object.status, 500)
            test.not_nil((string.find(object.body.error, "not a string", 1, true)))
        end)

        it("answers an unknown agent with 200 and a null agent", function()
            local by_name = install(agent_details, { agent = "host-routes-missing" })
            agent_details.handler()
            test.eq(by_name.status, 200)
            test.eq(by_name.headers["Cache-Control"], "no-store")
            test.eq(by_name.raw, '{"success":true,"agent":null}')

            local by_id = install(agent_details, { agent = "app.api:host_routes_missing_agent" })
            agent_details.handler()
            test.eq(by_id.status, 200)
            test.eq(by_id.raw, '{"success":true,"agent":null}')
        end)

        it("answers a private agent exactly like an unknown one", function()
            local by_name = install(agent_details, { agent = "host-routes-private" })
            agent_details.handler()
            test.eq(by_name.status, 200)
            test.eq(by_name.raw, '{"success":true,"agent":null}')

            local by_id = install(agent_details, { agent = "app.api:host_routes_private_agent" })
            agent_details.handler()
            test.eq(by_id.status, 200)
            test.eq(by_id.raw, '{"success":true,"agent":null}')
        end)

        it("answers a registry id that is not an agent with a null agent", function()
            local result = install(agent_details, { agent = "app.api:host_routes_titled_tool" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.raw, '{"success":true,"agent":null}')
        end)

        it("rejects a missing or empty agent parameter with 400", function()
            local missing = install(agent_details, {})
            agent_details.handler()
            test.eq(missing.status, 400)
            test.eq(missing.headers["Cache-Control"], "no-store")
            test.is_false(missing.body.success)
            test.not_nil(missing.body.error)

            local empty = install(agent_details, { agent = "" })
            agent_details.handler()
            test.eq(empty.status, 400)
            test.is_false(empty.body.success)
        end)

        it("rejects an unauthenticated request with 401", function()
            local result = install(agent_details, { agent = "host-routes-public" }, false)
            agent_details.handler()
            test.eq(result.status, 401)
            test.eq(result.headers["Cache-Control"], "no-store")
            test.is_false(result.body.success)
            test.eq(result.body.error, "Authentication required")
            test.is_nil(result.body.agent)
        end)
    end)

    describe("GET /tools/by-name", function()
        local original = {
            http = tools_by_name._http,
            security = tools_by_name._security,
            contract = catalog_client._contract,
            registry = tools_by_name._registry,
        }

        after_each(function()
            tools_by_name._http = original.http
            tools_by_name._security = original.security
            catalog_client._contract = original.contract
            tools_by_name._registry = original.registry
        end)

        it("answers a registry failure with 500", function()
            tools_by_name._registry = {
                find = function() return nil, "lookup failed" end,
            }
            local result = install(tools_by_name, { tools = "host_routes_titled_tool" })
            tools_by_name.handler()
            test.eq(result.status, 500)
            test.eq(result.headers["Cache-Control"], "no-store")
            test.is_false(result.body.success)
            test.eq(result.body.error, "tool lookup failed: lookup failed")
            test.is_nil(result.body.tools)
        end)

        it("finds tools by LLM name and by registry id", function()
            local result = install(tools_by_name, {
                tools = "host_routes_titled_tool,app.api:host_routes_plain_tool",
            })
            tools_by_name.handler()
            test.eq(result.status, 200)
            test.eq(result.content_type, http.CONTENT.JSON)
            test.eq(result.headers["Cache-Control"], "no-store")
            test.is_true(result.body.success)
            local found = result.body.tools
            test.eq(found["host_routes_titled_tool"].name, "host_routes_titled_tool")
            test.eq(found["host_routes_titled_tool"].title, "Titled Fixture Tool")
            test.eq(found["app.api:host_routes_plain_tool"].name, "host_routes_plain_tool")
        end)

        it("matches a tool by its llm_alias", function()
            local result = install(tools_by_name, { tools = "host_routes_alias,host_routes_aliased_tool" })
            tools_by_name.handler()
            test.eq(result.status, 200)
            local found = result.body.tools["host_routes_alias"]
            test.not_nil(found)
            test.eq(found.name, "host_routes_alias")
            test.eq(found.title, "Aliased Fixture Tool")
            test.is_nil(result.body.tools["host_routes_aliased_tool"])
        end)

        it("finds a tool by the sanitized name part of its registry id", function()
            local result = install(tools_by_name, { tools = "host_routes_dotted_tool,app.api:host_routes.dotted_tool" })
            tools_by_name.handler()
            test.eq(result.status, 200)
            test.eq(count_keys(result.body.tools), 2)
            test.eq(result.body.tools["host_routes_dotted_tool"].name, "host_routes_dotted_tool")
            test.eq(result.body.tools["app.api:host_routes.dotted_tool"].name, "host_routes_dotted_tool")
        end)

        it("reports a registry tool whose title is not a string, and still answers the other tools", function()
            local result = install(tools_by_name, { tools = "host_routes_titled_tool,host_routes_numeric_title_tool" })
            tools_by_name.handler()
            test.eq(result.status, 200)
            test.eq(count_keys(result.body.tools), 1)
            test.eq(result.body.tools["host_routes_titled_tool"].title, "Titled Fixture Tool")
            test.eq(result.body.errors["host_routes_numeric_title_tool"], "the answer for 'host_routes_numeric_title_tool' is not {name, title}")
        end)

        it("sends no errors field when every requested tool is in shape", function()
            local result = install(tools_by_name, { tools = "host_routes_titled_tool,host_routes_no_such_tool" })
            tools_by_name.handler()
            test.eq(result.status, 200)
            test.is_nil(result.body.errors)
        end)

        it("uses the LLM name as the title when the tool has none", function()
            local result = install(tools_by_name, { tools = "host_routes_plain_tool" })
            tools_by_name.handler()
            test.eq(result.body.tools["host_routes_plain_tool"].title, "host_routes_plain_tool")
        end)

        it("uses the LLM name as the title when the title is empty", function()
            local result = install(tools_by_name, { tools = "host_routes_empty_title_tool" })
            tools_by_name.handler()
            test.eq(result.body.tools["host_routes_empty_title_tool"].title, "host_routes_empty_title_tool")
        end)

        it("leaves out private tools by LLM name and by registry id", function()
            local result = install(tools_by_name, {
                tools = "host_routes_private_alias,app.api:host_routes_private_tool",
            })
            tools_by_name.handler()
            test.eq(result.status, 200)
            test.eq(json.encode(result.body.tools), "{}")
        end)

        it("trims names, skips empty items and leaves out unknown names", function()
            local result = install(tools_by_name, {
                tools = " host_routes_titled_tool ,, host_routes_no_such_tool ,",
            })
            tools_by_name.handler()
            test.eq(result.status, 200)
            test.eq(count_keys(result.body.tools), 1)
            test.not_nil(result.body.tools["host_routes_titled_tool"])
            test.is_nil(result.body.tools["host_routes_no_such_tool"])
        end)

        it("encodes an empty result as an empty object", function()
            local result = install(tools_by_name, { tools = "host_routes_no_such_tool" })
            tools_by_name.handler()
            test.eq(result.status, 200)
            test.eq(json.encode(result.body.tools), "{}")
            test.not_nil((string.find(result.raw, '"tools":{}', 1, true)))
        end)

        it("rejects a missing or empty tools parameter with 400", function()
            local missing = install(tools_by_name, {})
            tools_by_name.handler()
            test.eq(missing.status, 400)
            test.eq(missing.headers["Cache-Control"], "no-store")
            test.is_false(missing.body.success)
            test.not_nil(missing.body.error)

            local empty = install(tools_by_name, { tools = "" })
            tools_by_name.handler()
            test.eq(empty.status, 400)
            test.is_false(empty.body.success)
        end)

        it("rejects an unauthenticated request with 401", function()
            local result = install(tools_by_name, { tools = "host_routes_titled_tool" }, false)
            tools_by_name.handler()
            test.eq(result.status, 401)
            test.eq(result.headers["Cache-Control"], "no-store")
            test.is_false(result.body.success)
            test.eq(result.body.error, "Authentication required")
            test.is_nil(result.body.tools)
        end)

        it("leaves out an LLM name that two tools share, while both registry ids resolve", function()
            local result = install(tools_by_name, {
                tools = "host_routes_shared,app.api:host_routes_shared_one_tool,app.api:host_routes_shared_two_tool",
            })
            tools_by_name.handler()
            test.eq(result.status, 200)
            local found = result.body.tools
            test.eq(count_keys(found), 2)
            test.is_nil(found["host_routes_shared"])
            test.eq(found["app.api:host_routes_shared_one_tool"].name, "host_routes_shared")
            test.eq(found["app.api:host_routes_shared_one_tool"].title, "Shared One")
            test.eq(found["app.api:host_routes_shared_two_tool"].name, "host_routes_shared")
            test.eq(found["app.api:host_routes_shared_two_tool"].title, "Shared Two")
        end)

        it("finds a function.wasm tool by its LLM name and by its registry id", function()
            tools_by_name._registry = fake_registry({
                { id = "app.api:wasm_search_tool", kind = "function.wasm", meta = { type = "tool", title = "Wasm Search" } },
            })
            local result = install(tools_by_name, { tools = "wasm_search_tool,app.api:wasm_search_tool" })
            tools_by_name.handler()
            test.eq(result.status, 200)
            local found = result.body.tools
            test.eq(count_keys(found), 2)
            test.eq(found["wasm_search_tool"].name, "wasm_search_tool")
            test.eq(found["wasm_search_tool"].title, "Wasm Search")
            test.eq(found["app.api:wasm_search_tool"].name, "wasm_search_tool")
            test.eq(found["app.api:wasm_search_tool"].title, "Wasm Search")
        end)

        it("leaves out an LLM name that a function.wasm tool shares with a function.lua tool", function()
            tools_by_name._registry = fake_registry({
                { id = "app.api:lua_lookup_tool", kind = "function.lua", meta = { type = "tool", title = "Lua Lookup", llm_alias = "shared_lookup" } },
                { id = "app.api:wasm_lookup_tool", kind = "function.wasm", meta = { type = "tool", title = "Wasm Lookup", llm_alias = "shared_lookup" } },
            })
            local result = install(tools_by_name, {
                tools = "shared_lookup,app.api:lua_lookup_tool,app.api:wasm_lookup_tool",
            })
            tools_by_name.handler()
            test.eq(result.status, 200)
            local found = result.body.tools
            test.eq(count_keys(found), 2)
            test.is_nil(found["shared_lookup"])
            test.eq(found["app.api:lua_lookup_tool"].title, "Lua Lookup")
            test.eq(found["app.api:wasm_lookup_tool"].title, "Wasm Lookup")
        end)
    end)

    describe("Bound catalog contract", function()
        local original = {
            agent_http = agent_details._http,
            agent_security = agent_details._security,
            contract = catalog_client._contract,
            tools_http = tools_by_name._http,
            tools_security = tools_by_name._security,
            tools_registry = tools_by_name._registry,
        }

        after_each(function()
            agent_details._http = original.agent_http
            agent_details._security = original.agent_security
            catalog_client._contract = original.contract
            tools_by_name._http = original.tools_http
            tools_by_name._security = original.tools_security
            tools_by_name._registry = original.tools_registry
        end)

        it("answers agent details from the one bound implementation", function()
            local asked: any = nil
            local contract_module, calls = fake_contract({
                agent_details = function(_, input)
                    asked = input.agent
                    return {
                        id = "kickside:agent-7",
                        name = "agent-7",
                        title = "",
                        start_prompts = { "From the catalog" },
                    }
                end,
            })
            catalog_client._contract = contract_module
            local result = install(agent_details, { agent = "agent-7" })
            agent_details.handler()
            test.eq(calls.get[1], "wippy.session_util:catalog")
            test.eq(calls.open, 1)
            test.eq(asked, "agent-7")
            test.eq(result.status, 200)
            test.eq(result.body.agent.id, "kickside:agent-7")
            test.eq(result.body.agent.title, "agent-7")
            test.eq(#result.body.agent.start_prompts, 1)
            test.eq(result.body.agent.start_prompts[1], "From the catalog")
        end)

        it("answers a nil catalog result with 200 and a null agent, even for a public registry agent", function()
            local contract_module = fake_contract({
                agent_details = function() return nil end,
            })
            catalog_client._contract = contract_module
            local result = install(agent_details, { agent = "host-routes-public" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.raw, '{"success":true,"agent":null}')
        end)

        it("lets the catalog show an agent the built-in rule hides", function()
            local contract_module = fake_contract({
                agent_details = function()
                    return { id = "app.api:host_routes_private_agent", name = "host-routes-private", title = "Hidden Helper" }
                end,
            })
            catalog_client._contract = contract_module
            local result = install(agent_details, { agent = "host-routes-private" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.body.agent.title, "Hidden Helper")
            test.eq(#result.body.agent.start_prompts, 0)
        end)

        it("answers 500 when the catalog cannot be loaded, listed or opened, never the built-in answer", function()
            for _, failure in ipairs({
                { get_err = "contract not found" },
                { implementations_err = "permission denied" },
                { open_err = "binding failed" },
            }) do
                catalog_client._contract = fake_contract({}, failure.open_err, failure.implementations_err, failure.get_err)
                local cause = failure.get_err or failure.implementations_err or failure.open_err
                local agent = install(agent_details, { agent = "host-routes-public" })
                agent_details.handler()
                test.eq(agent.status, 500, cause)
                test.eq(agent.headers["Cache-Control"], "no-store", cause)
                test.is_false(agent.body.success)
                test.eq(agent.body.error, "agent lookup failed: " .. cause)

                local tools = install(tools_by_name, { tools = "host_routes_titled_tool" })
                tools_by_name.handler()
                test.eq(tools.status, 500, cause)
                test.eq(tools.body.error, "tool lookup failed: " .. cause)
            end
        end)

        it("answers 500 when a catalog call returns an error", function()
            catalog_client._contract = fake_contract({
                agent_details = function() return nil, "agent store down" end,
                tool_titles = function() return nil, "tool store down" end,
            })
            local agent = install(agent_details, { agent = "host-routes-public" })
            agent_details.handler()
            test.eq(agent.status, 500)
            test.eq(agent.body.error, "agent lookup failed: agent store down")

            local tools = install(tools_by_name, { tools = "host_routes_titled_tool" })
            tools_by_name.handler()
            test.eq(tools.status, 500)
            test.eq(tools.body.error, "tool lookup failed: tool store down")
        end)

        it("answers 500 for a catalog agent that is not in the contract's shape", function()
            local answers: any = {
                empty = {},
                number_name = { id = "kickside:agent-8", name = 8 },
                bool_title = { id = "kickside:agent-8", title = false },
                map_prompts = { id = "kickside:agent-8", start_prompts = { first = "Hi" } },
                number_prompt = { id = "kickside:agent-8", start_prompts = { "Hi", 42 } },
                string_answer = "kickside:agent-8",
            }
            catalog_client._contract = fake_contract({
                agent_details = function(_, input) return answers[input.agent] end,
            })
            for label in pairs(answers) do
                local result = install(agent_details, { agent = label })
                agent_details.handler()
                test.eq(result.status, 500, label)
                test.not_nil((string.find(result.body.error, "invalid agent for '" .. label .. "'", 1, true)), label)
            end
        end)

        it("answers tool titles from the bound implementation, only for the requested names", function()
            local asked: any = nil
            tools_by_name._registry = {
                find = function() error("the registry must not be read when a catalog is bound") end,
            }
            catalog_client._contract = fake_contract({
                tool_titles = function(_, input)
                    asked = input.names
                    return {
                        ["kickside_search"] = { name = "kickside_search", title = "Search" },
                        ["not_requested"] = { name = "not_requested", title = "Extra" },
                    }
                end,
            })
            local result = install(tools_by_name, { tools = " kickside_search , , unknown" })
            tools_by_name.handler()
            test.eq(#asked, 2)
            test.eq(asked[1], "kickside_search")
            test.eq(asked[2], "unknown")
            test.eq(result.status, 200)
            test.eq(count_keys(result.body.tools), 1)
            test.eq(result.body.tools["kickside_search"].title, "Search")
        end)

        it("keeps only the name and title of a catalog tool, with the name as the title fallback", function()
            catalog_client._contract = fake_contract({
                tool_titles = function()
                    return {
                        ["kickside_search"] = { name = "kickside_search", title = "", id = "kickside:search", config = { token = "x" } },
                    }
                end,
            })
            local result = install(tools_by_name, { tools = "kickside_search" })
            tools_by_name.handler()
            test.eq(result.status, 200)
            local search = result.body.tools["kickside_search"]
            test.eq(count_keys(search), 2)
            test.eq(search.name, "kickside_search")
            test.eq(search.title, "kickside_search")
            test.is_nil((string.find(result.raw, "token", 1, true)))
        end)

        it("answers 500 for a catalog tool answer that is not a map", function()
            for _, case in ipairs({
                { label = "nil" },
                { label = "string", value = "not a map" },
            }) do
                catalog_client._contract = fake_contract({
                    tool_titles = function() return case.value end,
                })
                local result = install(tools_by_name, { tools = "kickside_search" })
                tools_by_name.handler()
                test.eq(result.status, 500, case.label)
                test.eq(result.body.error, "tool lookup failed: the answer is not a map of tools", case.label)
            end
        end)

        it("reports each catalog tool entry that is not {name, title} by name, and still answers the other tools", function()
            catalog_client._contract = fake_contract({
                tool_titles = function()
                    return {
                        kickside_search = { name = "kickside_search", title = "Search" },
                        bad_boolean = true,
                        bad_no_title = { name = "bad_no_title" },
                        bad_no_name = { title = "No Name" },
                    }
                end,
            })
            local result = install(tools_by_name, { tools = "kickside_search,bad_boolean,bad_no_title,bad_no_name" })
            tools_by_name.handler()
            test.eq(result.status, 200)
            test.is_true(result.body.success)
            test.eq(count_keys(result.body.tools), 1)
            test.eq(result.body.tools["kickside_search"].title, "Search")
            test.eq(count_keys(result.body.errors), 3)
            for _, name in ipairs({ "bad_boolean", "bad_no_title", "bad_no_name" }) do
                test.eq(result.body.errors[name], "the answer for '" .. name .. "' is not {name, title}")
            end
        end)
    end)

    describe("No catalog binding", function()
        local original = {
            agent_http = agent_details._http,
            agent_security = agent_details._security,
            agent_contract = catalog_client._contract,
            tools_http = tools_by_name._http,
            tools_security = tools_by_name._security,
            tools_contract = catalog_client._contract,
        }

        after_each(function()
            agent_details._http = original.agent_http
            agent_details._security = original.agent_security
            catalog_client._contract = original.agent_contract
            tools_by_name._http = original.tools_http
            tools_by_name._security = original.tools_security
            catalog_client._contract = original.tools_contract
        end)

        it("uses the built-in agent rule and never opens the catalog", function()
            local contract_module, calls = fake_contract(nil)
            catalog_client._contract = contract_module
            local public = install(agent_details, { agent = "host-routes-public" })
            agent_details.handler()
            test.eq(public.body.agent.id, "app.api:host_routes_public_agent")

            local private = install(agent_details, { agent = "host-routes-private" })
            agent_details.handler()
            test.eq(private.raw, '{"success":true,"agent":null}')
            test.eq(#calls.get, 2)
            test.eq(calls.open, 0)
        end)

        it("uses the built-in tool rule and never opens the catalog", function()
            local contract_module, calls = fake_contract(nil)
            catalog_client._contract = contract_module
            local result = install(tools_by_name, { tools = "host_routes_titled_tool,host_routes_private_alias" })
            tools_by_name.handler()
            test.eq(count_keys(result.body.tools), 1)
            test.eq(result.body.tools["host_routes_titled_tool"].title, "Titled Fixture Tool")
            test.eq(#calls.get, 1)
            test.eq(calls.open, 0)
        end)

        it("finds no catalog implementation through the real contract module", function()
            local catalog, err = contract.get("wippy.session_util:catalog")
            test.is_nil(err)
            local implementations, implementations_err = catalog:implementations()
            test.is_nil(implementations_err)
            test.eq(#(implementations or {}), 0)
        end)

        it("defines the two catalog methods that the handlers call", function()
            local catalog, err = contract.get("wippy.session_util:catalog")
            test.is_nil(err)
            for _, name in ipairs({ "agent_details", "tool_titles" }) do
                local method, method_err = catalog:method(name)
                test.is_nil(method_err)
                test.not_nil(method)
            end
            local _, unknown_err = catalog:method("no_such_method")
            test.not_nil(unknown_err)
        end)
    end)

    describe("GET /agents/details with session_id", function()
        local original = {
            http = agent_details._http,
            security = agent_details._security,
            contract = catalog_client._contract,
            reader = agent_details._session_reader,
        }

        after_each(function()
            agent_details._http = original.http
            agent_details._security = original.security
            catalog_client._contract = original.contract
            agent_details._session_reader = original.reader
        end)

        it("answers with a private agent that a readable session runs", function()
            local reader, calls = fake_reader({ ["session-1"] = "host-routes-private" })
            agent_details._session_reader = reader
            local result = install(agent_details, { agent = "host-routes-private", session_id = "session-1" })
            agent_details.handler()
            test.eq(calls.open[1], "session-1")
            test.eq(result.status, 200)
            test.eq(result.body.agent.id, "app.api:host_routes_private_agent")
            test.eq(result.body.agent.title, "Hidden Helper")
            test.eq(result.body.agent.start_prompts[1], "Hidden prompt")
        end)

        it("answers a hidden agent with null when the session does not open", function()
            local reader, calls = fake_reader({})
            agent_details._session_reader = reader
            local result = install(agent_details, { agent = "host-routes-private", session_id = "session-denied" })
            agent_details.handler()
            test.eq(calls.open[1], "session-denied")
            test.eq(result.status, 200)
            test.eq(result.raw, '{"success":true,"agent":null}')
        end)

        it("answers a hidden agent with null when the session runs a different agent, and never reads the session for a visible one", function()
            local reader, calls = fake_reader({ ["session-2"] = "host-routes-public" })
            agent_details._session_reader = reader
            local private = install(agent_details, { agent = "host-routes-private", session_id = "session-2" })
            agent_details.handler()
            test.eq(private.raw, '{"success":true,"agent":null}')
            test.eq(#calls.open, 1)

            local public = install(agent_details, { agent = "host-routes-untitled", session_id = "session-2" })
            agent_details.handler()
            test.eq(public.body.agent.id, "app.api:host_routes_untitled_agent")
            test.eq(#calls.open, 1)
        end)

        it("answers a request by name for a session stored by registry id", function()
            agent_details._session_reader = fake_reader({ ["session-4"] = "app.api:host_routes_private_agent" })
            local result = install(agent_details, { agent = "host-routes-private", session_id = "session-4" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.body.agent.id, "app.api:host_routes_private_agent")
            test.eq(result.body.agent.title, "Hidden Helper")
        end)

        it("answers a request by registry id for a session stored by name", function()
            agent_details._session_reader = fake_reader({ ["session-5"] = "host-routes-private" })
            local result = install(agent_details, { agent = "app.api:host_routes_private_agent", session_id = "session-5" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.body.agent.id, "app.api:host_routes_private_agent")
            test.eq(result.body.agent.title, "Hidden Helper")
        end)

        it("matches the session's agent by registry id, not by name", function()
            agent_details._session_reader = fake_reader({ ["session-11"] = "app.api:host_routes_nameless_agent" })
            local result = install(agent_details, { agent = "app.api:host_routes_nameless_private_agent", session_id = "session-11" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.raw, '{"success":true,"agent":null}')
        end)

        it("answers a hidden agent with null when a session stored by id or by name runs a different agent", function()
            agent_details._session_reader = fake_reader({
                ["session-6"] = "app.api:host_routes_public_agent",
                ["session-7"] = "host-routes-public",
            })
            local by_name = install(agent_details, { agent = "host-routes-private", session_id = "session-6" })
            agent_details.handler()
            test.eq(by_name.raw, '{"success":true,"agent":null}')

            local by_id = install(agent_details, { agent = "app.api:host_routes_private_agent", session_id = "session-7" })
            agent_details.handler()
            test.eq(by_id.raw, '{"success":true,"agent":null}')
        end)

        it("answers from the session when a bound catalog hides the agent", function()
            local catalog_asked = false
            local contract_module, contract_calls = fake_contract({
                agent_details = function()
                    catalog_asked = true
                    return nil
                end,
            })
            catalog_client._contract = contract_module
            local reader, reader_calls = fake_reader({ ["session-8"] = "host-routes-private" })
            agent_details._session_reader = reader
            local result = install(agent_details, { agent = "host-routes-private", session_id = "session-8" })
            agent_details.handler()
            test.is_true(catalog_asked)
            test.eq(contract_calls.open, 1)
            test.eq(reader_calls.open[1], "session-8")
            test.eq(result.status, 200)
            test.eq(result.body.agent.id, "app.api:host_routes_private_agent")
            test.eq(result.body.agent.title, "Hidden Helper")
        end)

        it("keeps a bound catalog's answer for an agent the caller may see, and never reads the session", function()
            catalog_client._contract = fake_contract({
                agent_details = function()
                    return {
                        id = "app.api:host_routes_public_agent",
                        name = "host-routes-public",
                        title = "Tenant Helper",
                        start_prompts = { "Tenant prompt" },
                    }
                end,
            })
            local reader, reader_calls = fake_reader({ ["session-9"] = "host-routes-public" })
            agent_details._session_reader = reader
            local result = install(agent_details, { agent = "host-routes-public", session_id = "session-9" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.body.agent.title, "Tenant Helper")
            test.eq(#result.body.agent.start_prompts, 1)
            test.eq(result.body.agent.start_prompts[1], "Tenant prompt")
            test.eq(#reader_calls.open, 0)
        end)

        it("answers an agent that only the catalog knows from the catalog, without reading the session", function()
            local reader, reader_calls = fake_reader({ ["session-3"] = "app-specific:agent-9" })
            agent_details._session_reader = reader
            catalog_client._contract = fake_contract({
                agent_details = function(_, input)
                    return { id = input.agent, name = "agent-9", title = "Catalog Agent" }
                end,
            })
            local result = install(agent_details, { agent = "app-specific:agent-9", session_id = "session-3" })
            agent_details.handler()
            test.eq(result.status, 200)
            test.eq(result.body.agent.id, "app-specific:agent-9")
            test.eq(result.body.agent.title, "Catalog Agent")
            test.eq(#reader_calls.open, 0)
        end)

        it("answers 500 when the catalog fails, without falling back to session access", function()
            local reader, reader_calls = fake_reader({ ["session-10"] = "host-routes-private" })
            agent_details._session_reader = reader
            catalog_client._contract = fake_contract({}, "binding failed")
            local opened = install(agent_details, { agent = "host-routes-private", session_id = "session-10" })
            agent_details.handler()
            test.eq(opened.status, 500)
            test.eq(opened.body.error, "agent lookup failed: binding failed")

            catalog_client._contract = fake_contract({
                agent_details = function() return nil, "agent store down" end,
            })
            local called = install(agent_details, { agent = "host-routes-private", session_id = "session-10" })
            agent_details.handler()
            test.eq(called.status, 500)
            test.eq(called.body.error, "agent lookup failed: agent store down")
            test.eq(#reader_calls.open, 0)
        end)

        it("never opens a session without session_id", function()
            local reader, calls = fake_reader({ ["session-1"] = "host-routes-private" })
            agent_details._session_reader = reader
            local result = install(agent_details, { agent = "host-routes-private" })
            agent_details.handler()
            test.eq(#calls.open, 0)
            test.eq(result.raw, '{"success":true,"agent":null}')

            local empty = install(agent_details, { agent = "host-routes-private", session_id = "" })
            agent_details.handler()
            test.eq(#calls.open, 0)
            test.eq(empty.raw, '{"success":true,"agent":null}')
        end)
    end)

    describe("Contract binding actor", function()
        it("runs a bound contract function under the caller's actor", function()
            local actor = security.new_actor("session-util-actor-probe", {})
            local policy, policy_err = security.policy("app.api:actor_probe_policy")
            test.is_nil(policy_err)
            local scope = security.new_scope():with(policy)
            local result, err = funcs.new():with_actor(actor):with_scope(scope):call("app.api:actor_probe_caller")
            test.is_nil(err)
            test.eq(result.implementations, 1)
            test.eq(result.caller, "session-util-actor-probe")
            test.eq(result.binding, "session-util-actor-probe")
        end)
    end)
end

return test.run_cases(define_tests)
