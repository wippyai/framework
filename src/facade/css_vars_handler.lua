local http = require("http")
local theming = require("theming_helpers")

local function handler()
    local res = http.response()
    if not res then
        return nil, "no HTTP context"
    end

    -- Optional view-config resolver (wippy.facade:resolver): overrides win over the
    -- static requirement, so this CSS endpoint tones from the same source as
    -- /facade/config. No binding => {} => static defaults.
    local overrides = theming.resolve_overrides()
    local function get_req(name: string): string
        return theming.requirement(name, overrides)
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
