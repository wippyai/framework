-- wippy.facade:host_url returns the Web Host URL that the config endpoint
-- serves as facade_url: the application resolver's fe_facade_url, then a
-- module contribution (for example wippy/cdn-web-host), then the static
-- requirement default. Other modules call it instead of reading the static
-- requirement, so they load the same Host as the shell. The views fragment
-- gateway uses it to build fragment pages.
local theming = require("theming_helpers")
local config_contributors = require("config_contributors")

local function resolve(): string
    return theming.requirement("fe_facade_url", config_contributors.resolve_requirements())
end

return { resolve = resolve }
