local http = require("http")
local registry = require("registry")
local json = require("json")

local function app_title(): string
    local entry, _ = registry.get("wippy.facade:app_title")
    if entry and entry.data and type(entry.data.default) == "string" then
        return entry.data.default
    end
    return ""
end

-- Serves /facade/title.js: sets the tab title to app_title before the first
-- paint. The static SPA fallback (public/index.html) cannot render the title
-- on the server, so it loads this script right after its <title>.
local function handler()
    local res = http.response()
    if not res then
        return nil, "no HTTP context"
    end

    local body = ""
    local title = app_title()
    if title ~= "" then
        local literal, err = json.encode(title)
        if not err then
            body = "document.title = " .. literal .. ";\n"
        end
    end

    res:set_content_type("application/javascript")
    res:set_header("Cache-Control", "no-cache")
    res:set_status(http.STATUS.OK)
    res:write(body)
end

return { handler = handler }
