-- static_meta.lua
--
-- Finds the http.static mount that serves a view entry's URL path on this
-- server, and reads the entry's wippy-meta.json from that mount's
-- filesystem. The choice follows how the runtime's HTTP server serves
-- `<path>wippy-meta.json`:
--
-- - Each http.static entry is mounted on the server in its `meta.server`,
--   as the subtree pattern `<path>/` of a Go ServeMux. ServeMux cleans the
--   request path and picks the longest matching pattern.
-- - A plain mount serves the rest of the path below the mount from its
--   `fs`. A `spa: true` mount serves the whole request path from its `fs`,
--   and answers the index file when that file is missing.
-- - The `directory` field of http.static is not used by the runtime.
--
-- Views reads the file only when it can be sure the HTTP server would serve
-- the same file without further checks. In every other case it reports a
-- reason, and bundled_meta fetches the file over HTTP instead.
--
-- Only the wippy.views:read_static_meta function may open filesystems
-- (policy wippy.views:public_metadata_fs_runtime). The views API handlers
-- call that function, so they never hold fs.get themselves.

local fs = require("fs")
local registry = require("registry")

local M = {}

local META_FILE = "wippy-meta.json"

-- The views API endpoint whose router names the HTTP server that serves
-- the views API. Browsers load page files from PUBLIC_API_URL, the public
-- address of that same server.
local API_ENTRY = "wippy.views.api:render"

-- A wippy-meta.json larger than this is refused instead of read.
M.MAX_FILE_BYTES = 1024 * 1024

-- Middleware that decides neither who may read a file nor what it contains.
-- A mount with any other middleware (token_auth, resource_firewall,
-- sendfile, ...) is read over HTTP, so the server applies it.
local CONTENT_NEUTRAL_MIDDLEWARE = {
    cors = true,
    compress = true,
    real_ip = true,
    metrics = true,
    ratelimit = true,
}

-- Why the file is fetched over HTTP instead; bundled_meta logs the reason.
M.REASON = {
    remote = "the entry URL is on another host",
    encoded = "the entry path is URL-encoded",
    placeholder = "an http.static path on this server uses a placeholder that views cannot resolve",
    no_mount = "no http.static mount on this server serves the path",
    ambiguous = "more than one http.static mount could serve the path",
    middleware = "the http.static mount for the path uses middleware that only the HTTP server applies",
    catch_all = "only the catch-all / mount matches the path and it has no such file",
}

-- Clean a URL path the way Go's ServeMux does before it routes a request:
-- collapse repeated slashes and resolve "." and ".." segments. Keeps a
-- trailing slash. An entry with only `base_path: /x` resolves to "//x/",
-- which browsers reach through the server's redirect to "/x/".
function M.clean_path(p: string): string
    local parts: {string} = {}
    for segment in p:gmatch("[^/]+") do
        if segment == ".." then
            if #parts > 0 then
                table.remove(parts)
            end
        elseif segment ~= "." then
            table.insert(parts, segment)
        end
    end
    local cleaned = "/" .. table.concat(parts, "/")
    if #parts > 0 and p:sub(-1) == "/" then
        cleaned = cleaned .. "/"
    end
    return cleaned
end

-- Qualify a relative registry ID (`fs: ui_static_fs`) with the namespace of
-- the entry that declares it, as the runtime does.
local function qualify_id(entry_id: string, relative_id: string): string
    if relative_id:find(":", 1, true) then
        return relative_id
    end
    return registry.parse_id(entry_id).ns .. ":" .. relative_id
end

-- SPA mode as the runtime decodes it: the legacy `options.spa` (bool, or
-- the string "true") wins over `static_options.spa` when it is set.
local function is_spa(data: any): boolean
    local legacy: any = nil
    if type(data.options) == "table" then
        legacy = data.options.spa
    end
    if type(legacy) == "boolean" then
        return legacy
    end
    if type(legacy) == "string" then
        return legacy == "true"
    end
    return type(data.static_options) == "table" and data.static_options.spa == true
end

-- Names of the mount's middleware that may change who reads the file or
-- what it contains, or nil when there is none.
local function guarding_middleware(data: any): string?
    if type(data.middleware) ~= "table" then
        return nil
    end
    local names: {string} = {}
    for _, name in ipairs(data.middleware) do
        if not CONTENT_NEUTRAL_MIDDLEWARE[tostring(name)] then
            table.insert(names, tostring(name))
        end
    end
    if #names == 0 then
        return nil
    end
    return table.concat(names, ", ")
end

-- The HTTP server that serves the views API: the server of the router that
-- the wippy.views api_router requirement points at. Nil when it cannot be
-- resolved.
function M.api_server(): string?
    local render = registry.get(API_ENTRY)
    local router_id = render and render.meta and render.meta.router
    if type(router_id) ~= "string" or router_id == "" then
        return nil
    end
    router_id = qualify_id(API_ENTRY, router_id)
    local router = registry.get(router_id)
    local server = router and router.meta and router.meta.server
    if type(server) ~= "string" or server == "" then
        return nil
    end
    return qualify_id(router_id, server)
end

-- Pick the mount that the HTTP server would use for `<base_path>wippy-meta.json`.
-- `entries` are http.static registry entries. `server` limits the choice
-- to that HTTP server; without it, any second server makes the choice
-- ambiguous. Returns { id, fs, file, catch_all, spa } or nil and a reason
-- from M.REASON.
function M.select_mount(entries: {any}, base_path: string, server: string?): (any, string?)
    if base_path:sub(1, 1) ~= "/" then
        return nil, M.REASON.remote
    end
    if base_path:find("%", 1, true) then
        return nil, M.REASON.encoded
    end
    local path = M.clean_path(base_path)

    local best_len = -1
    local found: {any} = {}
    local servers: {[string]: boolean} = {}
    local server_count = 0
    for _, entry in ipairs(entries) do
        local data: any = entry.data or {}
        local meta: any = entry.meta or {}
        local id = tostring(entry.id)
        local mount, fs_id = data.path, data.fs
        local mount_server = type(meta.server) == "string" and meta.server ~= "" and qualify_id(id, meta.server) or nil
        if mount_server and not servers[mount_server] then
            servers[mount_server] = true
            server_count = server_count + 1
        end
        if (server == nil or mount_server == server)
            and type(mount) == "string" and mount:sub(1, 1) == "/"
            and type(fs_id) == "string" and fs_id ~= "" then
            if mount:find("${", 1, true) then
                return nil, M.REASON.placeholder
            end
            -- "/app/keeper" and "/app/keeper/" mount the same subtree; "/" becomes "".
            local prefix = (mount:gsub("/+$", ""))
            local len = #prefix
            if len >= best_len and path:sub(1, len + 1) == prefix .. "/" then
                if len > best_len then
                    best_len = len
                    found = {}
                end
                table.insert(found, { id = id, fs = qualify_id(id, fs_id), data = data, len = len })
            end
        end
    end

    if server == nil and server_count > 1 then
        return nil, M.REASON.ambiguous
    end
    if #found == 0 then
        return nil, M.REASON.no_mount
    end
    if #found > 1 then
        return nil, M.REASON.ambiguous
    end

    local mount = found[1]
    local guard = guarding_middleware(mount.data)
    if guard then
        return nil, M.REASON.middleware .. " (" .. guard .. ")"
    end
    local spa = is_spa(mount.data)
    return {
        id = mount.id,
        fs = mount.fs,
        -- The SPA handler serves the whole request path from its
        -- filesystem; a plain mount serves the path below the mount.
        file = (spa and path:sub(2) or path:sub(mount.len + 2)) .. META_FILE,
        catch_all = mount.len == 0,
        spa = spa,
    }, nil
end

-- Find the mount for a base path among this server's http.static entries.
function M.find_mount(base_path: string): (any, string?)
    if base_path:sub(1, 1) ~= "/" then
        return nil, M.REASON.remote
    end
    local entries, err = registry.find({ [".kind"] = "http.static" })
    if err or not entries then
        return nil, "the registry could not list http.static entries (" .. tostring(err or "no result") .. ")"
    end
    return M.select_mount(entries, base_path, M.api_server())
end

-- Read the mount's wippy-meta.json. Returns a table with `status`:
--   "found"       `body` holds the file;
--   "missing"     the mount has no such file (an entry without bundled meta);
--   "error"       `err` says why the file could not be read;
--   "unavailable" `reason` says why the caller should fetch over HTTP.
-- `source` names the filesystem and file.
function M.read(mount: any, max_bytes: number?): any
    local limit = max_bytes or M.MAX_FILE_BYTES
    local source = mount.fs .. "/" .. mount.file
    local volume, get_err = fs.get(mount.fs)
    if not volume then
        return {
            status = "unavailable",
            reason = "the mount filesystem " .. mount.fs .. " could not be opened (" .. tostring(get_err) .. ")",
            source = source,
        }
    end

    -- The runtime reports every stat failure as "not found", so a permission
    -- or I/O error on the file also looks like a missing file here.
    local info = volume:stat(mount.file)
    if not info then
        if mount.catch_all then
            -- A route on this server may serve the path instead of the
            -- catch-all mount, so only HTTP can tell.
            return { status = "unavailable", reason = M.REASON.catch_all, source = source }
        end
        return { status = "missing", source = source }
    end
    if info.is_dir then
        return { status = "error", err = "the path is a directory", source = source }
    end
    if type(info.size) == "number" and info.size > limit then
        return { status = "error", err = "the file is larger than " .. tostring(limit) .. " bytes", source = source }
    end

    local body, read_err = volume:readfile(mount.file)
    if read_err then
        return { status = "error", err = "cannot read the file (" .. tostring(read_err) .. ")", source = source }
    end
    return { status = "found", body = body, source = source }
end

-- Find the mount and read the file: what wippy.views:read_static_meta runs.
function M.load(base_path: string): any
    local mount, reason = M.find_mount(base_path)
    if not mount then
        return { status = "unavailable", reason = reason }
    end
    return M.read(mount)
end

return M
