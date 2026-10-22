local fs = require("fs")

-- Test seam: tries fs.get as a funcs.call target, so tests can check
-- which security scopes may open a filesystem
-- (funcs.new():with_actor():with_scope()).
local function run(fs_id: string)
    local volume, err = fs.get(fs_id)
    return { opened = volume ~= nil, err = err and tostring(err) or nil }
end

return { run = run }
