local fs = require("fs")
local json = require("json")
local registry = require("registry")
local contract = require("contract")
local logger = require("logger"):named("facade")

local helpers = {}

local NS = "wippy.facade:"
-- Optional contract an application binds to override facade requirement values at
-- request time (see the `resolver` contract.definition).
local RESOLVER_CONTRACT = "wippy.facade:resolver"

local function get_contract(): any return helpers._contract or contract end
local function get_logger(): any return helpers._logger or logger end

-- Get a named filesystem instance by registry entry ID.
-- Returns nil (does not raise) when entry_id is empty or the named filesystem
-- does not exist, so callers degrade gracefully when content_fs is unconfigured.
function helpers.get_fs(entry_id: string): any
    if entry_id == "" then
        return nil
    end
    local ok, result = pcall(function()
        return fs.get(entry_id)
    end)
    if not ok then
        return nil
    end
    return result
end

-- Detect a content_fs file-reference and return the path inside the fs, or nil
-- when the value is an inline string (not a reference).
--
-- `fs://path` is the canonical scheme for values supplied via YAML requirement
-- params: the wippy loader reserves `file://` for its OWN load-time
-- interpolation (it would read the file relative to the _index.yaml and inline
-- it before the facade ever sees the literal), so a `file://` written in YAML
-- never reaches here. `file://path` is still accepted for values supplied via
-- non-YAML paths (env vars, `-o` overrides, runtime registry edits), where the
-- loader does not interpolate.
function helpers.file_ref_path(value: string): string?
    if value:sub(1, 5) == "fs://" then
        return value:sub(6)
    end
    if value:sub(1, 7) == "file://" then
        return value:sub(8)
    end
    return nil
end

-- Resolve a possibly-referenced CSS string to its content.
-- If value is an "fs://"/"file://" reference, reads the path from file_sys and
-- returns the file content. Returns "" when file_sys is nil or the file is
-- unreadable, so the caller's non_empty_or_nil() check suppresses the field.
function helpers.resolve_css(value: string, file_sys: any): string
    local path = helpers.file_ref_path(value)
    if path == nil then
        return value
    end
    if not file_sys then
        return ""
    end
    local ok, content = pcall(function()
        return (file_sys :: any):readfile(path :: string)
    end)
    if not ok or content == nil then
        return ""
    end
    return (content :: string)
end

-- Resolve a possibly-referenced JSON string and decode it as a map.
-- If value is an "fs://"/"file://" reference, reads the path from file_sys first.
-- Returns {} when file_sys is nil, the file is unreadable, or JSON is invalid.
function helpers.resolve_json(value: string, file_sys: any): {[string]: any}
    local path = helpers.file_ref_path(value)
    if path == nil then
        if value == "" then
            return {}
        end
        local decoded, err = json.decode(value)
        if err then
            return {}
        end
        return (decoded :: {[string]: any}) or {}
    end
    if not file_sys then
        return {}
    end
    local ok, content = pcall(function()
        return (file_sys :: any):readfile(path :: string)
    end)
    if not ok or content == nil then
        return {}
    end
    local decoded, err = json.decode(content :: string)
    if err then
        return {}
    end
    return (decoded :: {[string]: any}) or {}
end

-- Generate a CSS string from a cssVariables map, mirroring gen-2-chat's
-- createCssVariables(). Flat string entries → :root {}. "@dark"/"@light"
-- entries compile to the three-state forcing model: an OS media query gated
-- against the opposite forced scope (:root:not(.w-theme-*)) PLUS a forced
-- .w-theme-* class rule, so they respond to a forced themeMode as well as the OS
-- preference. Keys without a "--" prefix get it prepended automatically.
-- Returns "" for an empty or nil input.
function helpers.build_variables_css(vars: {[string]: any}): string
    if not vars or next(vars) == nil then
        return ""
    end

    local function to_var(key: string, value: string): string
        local k: string = key:sub(1, 2) == "--" and key or ("--" .. key)
        return k .. ": " .. value .. ";"
    end

    local function to_block(map: {[string]: any}): string
        local parts: {string} = {}
        for k, v in pairs(map) do
            if type(v) == "string" then
                table.insert(parts, to_var(k, v :: string))
            end
        end
        return table.concat(parts, "\n")
    end

    local root_parts: {string} = {}
    local media_parts: {string} = {}

    for key, value in pairs(vars) do
        if (key == "@dark" or key == "@light") and type(value) == "table" then
            local block = to_block(value :: {[string]: any})
            if block ~= "" then
                if key == "@dark" then
                    table.insert(media_parts, "@media (prefers-color-scheme: dark) { :root:not(.w-theme-light) { " .. block .. " } }")
                    table.insert(media_parts, ":root.w-theme-dark, .w-theme-dark { " .. block .. " }")
                else
                    table.insert(media_parts, "@media (prefers-color-scheme: light) { :root:not(.w-theme-dark) { " .. block .. " } }")
                    table.insert(media_parts, ":root.w-theme-light, .w-theme-light { " .. block .. " }")
                end
            end
        elseif type(value) == "string" then
            table.insert(root_parts, to_var(key, value :: string))
        end
    end

    local css_parts: {string} = {}
    if #root_parts > 0 then
        table.insert(css_parts, ":root { " .. table.concat(root_parts, "\n") .. " }")
    end
    for _, m in ipairs(media_parts) do
        table.insert(css_parts, m)
    end

    return table.concat(css_parts, "\n")
end

-- Requirement overrides from the bound wippy.facade:resolver, as a name -> value
-- map. An unbound resolver is detected structurally and yields {}. The view must
-- always render, so a bound resolver that fails is logged and the static
-- ns.requirement defaults apply.
function helpers.resolve_overrides(): {[string]: any}
    local resolver_contract, get_err = get_contract().get(RESOLVER_CONTRACT)
    if get_err then
        get_logger():warn("facade resolver contract unavailable", { error = tostring(get_err) })
        return {}
    end

    local implementations, implementations_err = resolver_contract:implementations()
    if implementations_err then
        get_logger():warn("facade resolver implementations unavailable", { error = tostring(implementations_err) })
        return {}
    end
    if not implementations or #implementations == 0 then
        return {}
    end

    local instance, open_err = resolver_contract:open()
    if open_err then
        get_logger():warn("facade resolver failed to open", { error = tostring(open_err) })
        return {}
    end

    local overrides, resolve_err = instance:resolve({})
    if resolve_err then
        get_logger():warn("facade resolver failed", { error = tostring(resolve_err) })
        return {}
    end
    if type(overrides) ~= "table" then
        get_logger():warn("facade resolver returned a non-table result", { error = "got " .. type(overrides) })
        return {}
    end
    return overrides :: {[string]: any}
end

-- requirement: the value for a facade requirement, preferring a resolver override
-- (a string) over the static registry default. Mirrors the handlers' get_req so a
-- resolver can replace any requirement (css_variables, custom_css, app_title, ...).
-- Override values use the same format as the static default (JSON-encoded for the
-- JSON requirements such as css_variables); omitted keys fall back to the default.
function helpers.requirement(name: string, overrides: {[string]: any}?): string
    if overrides then
        local ov = (overrides :: {[string]: any})[name]
        if type(ov) == "string" then
            return ov :: string
        end
    end
    local entry, _ = registry.get(NS .. name)
    if entry and entry.data then
        return entry.data.default or ""
    end
    return ""
end

return helpers
