local bundled_meta = require("bundled_meta")

-- Test seam: exposes bundled_meta._load as a funcs.call target so tests can
-- run it under the handler security policies
-- (funcs.new():with_actor():with_scope()), which a direct library call
-- cannot do.
local function run(base_path: string, base_url: string)
    local meta, err, source, over_http, via = bundled_meta._load(base_path, base_url)
    return { meta = meta, err = err, source = source, over_http = over_http, via = via }
end

return { run = run }
