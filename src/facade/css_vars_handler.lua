local http = require("http")
local registry = require("registry")
local theming = require("theming_helpers")

local NS = "wippy.facade:"

local function get_req(name: string): string
    local entry, _ = registry.get(NS .. name)
    if entry and entry.data then
        return entry.data.default or ""
    end
    return ""
end

local function handler()
    local res = http.response()
    if not res then
        return nil, "no HTTP context"
    end

    local file_sys = theming.get_fs(get_req("content_fs"))
    local vars = theming.resolve_json(get_req("css_variables"), file_sys)

    local css = theming.build_variables_css(vars)

    res:set_content_type("text/css")
    res:set_header("Cache-Control", "public, max-age=3600")
    res:set_status(http.STATUS.OK)
    res:write(css)
end

return { handler = handler }
