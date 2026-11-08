-- fragment_gateway.lua (EE2-2313)
--
-- Web-Fragments gateway endpoint on /@fragment/{id}/{path...}. The request
-- handling lives in fragment_service; this handler passes it the runtime
-- modules. Auth is not injected here (client-held): the fragment proxy
-- performs the GetConfig/SetConfig handshake with the Host.

local http = require("http")
local http_client = require("http_client")
local registry = require("registry")
local funcs = require("funcs")
local json = require("json")
local time = require("time")
local logger = require("logger")
local page_registry = require("page_registry")
local bundled_meta = require("bundled_meta")
local facade_host = require("facade_host")
local fragment_service = require("fragment_service")

local log = logger:named("wippy.views.fragment_gateway")

local function warn(message, fields)
    log:warn(message, fields)
end

local host_deps = {
    registry_get = registry.get,
    call = funcs.call,
    log = warn,
}

local deps = {
    get_page = page_registry.get,
    can_access = page_registry.can_access,
    resolve_base_url = page_registry.resolve_base_url,
    page_meta = bundled_meta.fetch_for_page,
    -- fe_facade_url (Web Host bundle URL), resolved the way the facade's
    -- config endpoint resolves it, so fragment pages load the same Host as
    -- the shell.
    facade_url = function()
        return facade_host.url(host_deps)
    end,
    http_get = http_client.get,
    decode_json = json.decode,
    now = function()
        return time.now():unix()
    end,
    log = warn,
}

local function handler()
    local req = http.request()
    local res = http.response()
    if not req or not res then
        return nil, "Failed to get HTTP context"
    end
    fragment_service.serve(req, res, deps)
end

return { handler = handler }
