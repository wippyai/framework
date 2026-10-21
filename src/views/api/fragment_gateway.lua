-- fragment_gateway.lua (EE2-2313)
--
-- Web-Fragments gateway endpoint on /@fragment/{id}/{path...}. The request
-- handling lives in fragment_service; this handler passes it the runtime
-- modules. Auth is not injected here (client-held): the fragment proxy
-- performs the GetConfig/SetConfig handshake with the Host.

local http = require("http")
local http_client = require("http_client")
local registry = require("registry")
local json = require("json")
local time = require("time")
local logger = require("logger")
local page_registry = require("page_registry")
local bundled_meta = require("bundled_meta")
local fragment_service = require("fragment_service")

local log = logger:named("wippy.views.fragment_gateway")

local deps = {
    get_page = page_registry.get,
    can_access = page_registry.can_access,
    resolve_base_url = page_registry.resolve_base_url,
    page_meta = bundled_meta.fetch_for_page,
    -- fe_facade_url (Web Host bundle URL), read the way the facade's config
    -- handler reads it.
    facade_url = function()
        local entry = registry.get("wippy.facade:fe_facade_url")
        return entry and entry.data and entry.data.default or nil
    end,
    http_get = http_client.get,
    decode_json = json.decode,
    now = function()
        return time.now():unix()
    end,
    log = function(message, fields)
        log:warn(message, fields)
    end,
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
