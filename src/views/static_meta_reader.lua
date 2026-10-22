local static_meta = require("static_meta")

-- Reads the wippy-meta.json that an http.static mount on this server serves
-- for a view entry's base path. This is the only views function that may
-- open filesystems (policy wippy.views:public_metadata_fs_runtime); the
-- views API handlers call it through funcs, so they never hold fs.get.
local function run(base_path: string): any
    if type(base_path) ~= "string" or base_path == "" then
        return { status = "unavailable", reason = "the entry has no URL path" }
    end
    return static_meta.load(base_path)
end

return { run = run }
