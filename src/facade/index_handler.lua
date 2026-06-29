local http = require("http")
local registry = require("registry")
local templates = require("templates")

local NS = "wippy.facade:"
local TEMPLATE_SET = NS .. "templates"

local function get_req(name: string): string
    local entry, _ = registry.get(NS .. name)
    if entry and entry.data then
        return entry.data.default or ""
    end
    return ""
end

-- Pull a single cookie value out of the raw Cookie header
-- ("a=1; @wippy-theme-mode=dark; b=2" → "dark"). Plain string match — no
-- pattern metachars from `name` reach gsub (we compare with ==).
local function cookie_value(header: string?, name: string): string?
    if not header or header == "" then
        return nil
    end
    for pair in header:gmatch("[^;]+") do
        local k, v = pair:match("^%s*(.-)%s*=%s*(.*)$")
        if k == name then
            return v
        end
    end
    return nil
end

-- Renders the facade shell (index.jet). The only server-side dynamic part is the
-- theme: in "cookie" persistence mode the stored mode is read from the request
-- cookie and the matching w-theme-* class is baked onto <html> so the very first
-- paint is already themed (no flash). "localStorage"/"none" render no class — the
-- served theme-persist.js handles those client-side.
local function handler()
    local req = http.request()
    local res = http.response()
    if not res then
        return nil, "no HTTP context"
    end

    local persist = get_req("theme_persist")
    local key = get_req("theme_storage_key")
    if key == "" then
        key = "@wippy-theme-mode"
    end

    local has_theme = false
    local theme_class = ""
    local color_scheme = ""
    if persist == "cookie" and req then
        local stored = cookie_value(req:header("Cookie"), key)
        if stored == "dark" then
            has_theme = true
            theme_class = "w-theme-dark"
            color_scheme = "dark"
        elseif stored == "light" then
            has_theme = true
            theme_class = "w-theme-light"
            color_scheme = "light"
        end
    end

    local set = templates.get(TEMPLATE_SET)
    local html, err = set:render("index", {
        hasTheme = has_theme,
        themeClass = theme_class,
        colorScheme = color_scheme,
    })
    if err then
        res:set_status(http.STATUS.INTERNAL_SERVER_ERROR)
        res:set_content_type("text/html")
        res:write("<!doctype html><meta charset=\"utf-8\"><title>Wippy</title>Failed to render shell.")
        return nil, err
    end

    res:set_content_type("text/html")
    -- The shell embeds a per-user theme from a cookie; never cache across users.
    res:set_header("Cache-Control", "no-store")
    res:set_status(http.STATUS.OK)
    res:write(html)
end

return { handler = handler }
