local registry = require("registry")
local security = require("security")
local env = require("env")

type PageInfo = {
    id: string,
    name: string,
    title: string,
    icon: string,
    order: number,
    group: string,
    group_icon: string,
    group_order: number,
    group_placement: string,
    secure: boolean,
    parent: string?,
    public: boolean,
    announced: boolean,
    inline: boolean,
    kind: string,
    url: string?,
    internal: string?,
    mount_route: string?,
}

type PageDetail = PageInfo & {
    template_set: string?,
    template_name: string?,
    data_func: string?,
    resources: {string}?,
    content_type: string,
    source: string?,
    proxy: {[string]: any}?,
    base_path: string?,
    entry_point: string?,
    render_engine: string?,
}

local pages = {}

-- Qualify a relative ID with the entry's namespace
local function qualify_id(entry_id, relative_id)
    if relative_id:find(":") then
        return relative_id
    end
    return registry.parse_id(entry_id).ns .. ":" .. relative_id
end

-- Determine the page kind from the registry entry kind
local function detect_kind(entry_kind)
    if entry_kind == "template.jet" then
        return "template"
    end
    return "component"
end

-- Extract common page metadata from a registry entry
local function extract_page_info(entry)
    local meta = entry.meta
    local kind = detect_kind(entry.kind)

    local info = {
        id = entry.id,
        -- Raw YAML values (may be nil when omitted). Defaults belong to the
        -- projection layer (`bundled_meta.project_page_response`) so that
        -- `name or w.name or meta.name` actually falls through. Lua "" is
        -- truthy and would block the bundled-meta fallback chain.
        name = meta.name,
        title = meta.title,
        icon = meta.icon or "",
        order = meta.order or 9999,
        group = meta.group or "",
        group_icon = meta.group_icon or "",
        group_order = meta.group_order or 9999,
        group_placement = meta.group_placement or "default",
        secure = meta.secure or false,
        parent = meta.parent,
        public = meta.public or false,
        announced = meta.announced or meta.public or false,
        inline = meta.inline or false,
        internal = meta.internal or "",
        kind = kind,
        config_overrides = meta.config_overrides,
        -- `meta.proxy` (camelCase overlay) is the single proxy field. Raw (nil
        -- when omitted); the projection/synthesis layer applies defaults.
        proxy = meta.proxy,
        -- EE2-2313: per-page render engine override (auto|iframe|fragment). Raw/nil.
        render_engine = meta.render_engine,
        mount_route = meta.mountRoute,
    }

    if kind == "component" then
        info.url = meta.url or meta.public_url
    end

    return info
end

-- Find all virtual pages in the registry
function pages.find_all()
    local entries, err = registry.find({
        ["meta.type"] = "view.page"
    })

    if err then
        return nil, "Failed to find virtual pages: " .. tostring(err)
    end

    if not entries or #entries == 0 then
        return {}
    end

    local pages_list = {}
    for _, entry in ipairs(entries) do
        if entry.meta then
            table.insert(pages_list, extract_page_info(entry))
        end
    end

    table.sort(pages_list, function(a, b)
        if a.order == b.order then
            return a.title < b.title
        end
        return a.order < b.order
    end)

    return pages_list
end

-- Get a single page by ID
function pages.get(page_id)
    if not page_id then
        return nil, "Page ID is required"
    end

    local entry, err = registry.get(page_id)
    if err or not entry then
        return nil, "Page not found: " .. (err or "unknown error")
    end

    local meta_type = entry.meta and entry.meta.type
    if meta_type ~= "view.page" and meta_type ~= "view.component" then
        return nil, "Invalid page type for ID: " .. page_id
    end

    local kind = detect_kind(entry.kind)
    local full_id = registry.parse_id(entry.id)

    local page = {
        id = entry.id,
        -- Raw YAML values (may be nil when omitted). Same rationale as
        -- extract_page_info — the projection's `or` chain depends on nil
        -- propagation. "" is truthy in Lua and would block bundled fallback.
        name = entry.meta.name,
        title = entry.meta.title,
        icon = entry.meta.icon or "",
        order = entry.meta.order or 9999,
        group = entry.meta.group or "",
        group_icon = entry.meta.group_icon or "",
        group_order = entry.meta.group_order or 9999,
        group_placement = entry.meta.group_placement or "default",
        secure = entry.meta.secure or false,
        parent = entry.meta.parent,
        public = entry.meta.public or false,
        announced = entry.meta.announced or entry.meta.public or false,
        inline = entry.meta.inline or false,
        kind = kind,
        content_type = entry.meta.content_type or "text/html",
        config_overrides = entry.meta.config_overrides,
        -- `meta.proxy` (camelCase overlay) is the single proxy field. Raw (nil
        -- when omitted); the projection/synthesis layer applies defaults.
        proxy = entry.meta.proxy,
        -- EE2-2313: per-page render engine override (auto|iframe|fragment). Raw/nil.
        render_engine = entry.meta.render_engine,
        mount_route = entry.meta.mountRoute,
    }

    if kind == "template" then
        local template_set = entry.data.set
        template_set = qualify_id(entry.id, template_set)

        local data_func = entry.data.data_func
        if data_func and data_func ~= "" then
            data_func = qualify_id(entry.id, data_func)
        end

        local resources = {}
        if entry.data.resources then
            for i, resource_id in ipairs(entry.data.resources) do
                resources[i] = qualify_id(entry.id, resource_id)
            end
        end

        page.template_set = template_set
        page.template_name = entry.meta.name or full_id.name
        page.data_func = data_func
        page.resources = resources
        page.source = rawget(entry, "source")
    else
        page.url = entry.meta.url or entry.meta.public_url
        page.base_path = entry.meta.base_path

        -- Raw YAML entry_point (may be nil when omitted). Callers that need
        -- a default-filled value should compute it at their layer:
        --   - synthesize_from_registry (legacy path) applies the historical
        --     defaults (index.html for view.page, index.js for view.component)
        --     to preserve pre-0.4.32 wire compatibility.
        --   - bundled_meta projection treats nil as "no YAML opinion" so the
        --     bundled wippy.path / browser field can fill in. This is what
        --     makes YAML-first priority work — a missing YAML field MUST be
        --     distinguishable from a YAML field with the default value.
        page.entry_point = entry.meta.entry_point
    end

    return page
end

-- Resolve a page URL to an absolute base URL with trailing slash.
-- When base_path is set, it is appended to the URL to form the project root.
-- Entry point paths are relative to this resolved base.
function pages.resolve_base_url(page)
    local base_url = page.url or ""

    -- Append base_path to get the project root
    local base_path = page.base_path or ""
    if base_path ~= "" then
        if not base_url:match("/$") then
            base_url = base_url .. "/"
        end
        base_url = base_url .. base_path
    end

    local origin = env.get("PUBLIC_API_URL") or ""

    if origin ~= "" and base_url ~= "" and not base_url:match("^https?://") then
        base_url = origin .. base_url
    end

    if base_url ~= "" and not base_url:match("/$") then
        base_url = base_url .. "/"
    end

    return base_url
end

-- Mount route v1 syntax validator.
-- Canonical forms:
--   /:part(.*)*                root mount
--   /<literal>/:part(.*)*      prefix mount (one or more literal segments)
--   /<lit1>/<lit2>/:part(.*)*  nested prefix mount
-- Literal segments: lowercase alphanumerics plus hyphens.
-- The `:part` param name matches the gen-2-chat frontend convention.
local MOUNT_ROUTE_SUFFIX = "/:part(.*)*"

local function validate_mount_route_syntax(route)
    if type(route) ~= "string" or #route < #MOUNT_ROUTE_SUFFIX then
        return false
    end

    -- Required catch-all suffix
    local tail = route:sub(-#MOUNT_ROUTE_SUFFIX)
    if tail ~= MOUNT_ROUTE_SUFFIX then
        return false
    end

    -- Everything before the suffix is the literal prefix
    local prefix = route:sub(1, #route - #MOUNT_ROUTE_SUFFIX)

    -- Root mount: "/:part(.*)*" → prefix is empty, legal
    if prefix == "" then
        return true
    end

    -- Must start with /
    if prefix:sub(1, 1) ~= "/" then
        return false
    end

    -- Parse segments: each must match [a-z0-9-]+, joined by single /
    local rebuilt = ""
    for segment in prefix:gmatch("/([^/]+)") do
        if not segment:match("^[a-z0-9%-]+$") then
            return false
        end
        rebuilt = rebuilt .. "/" .. segment
    end

    -- Ensure rebuilt prefix matches input (catches trailing slash, //, etc.)
    return rebuilt == prefix
end

-- Build an error message for an invalid-syntax mountRoute.
local function mount_route_syntax_error(page_id, route)
    return string.format(
        '[views] page "%s" has invalid mountRoute "%s"'
        .. ' — v1 only supports "/<literal>/:part(.*)*" and "/:part(.*)*".'
        .. ' Literal segments must be lowercase alphanumerics plus hyphens.'
        .. ' Use ":part" (not ":pathMatch") to match the gen-2-chat system-route convention.',
        tostring(page_id), tostring(route)
    )
end

-- Build an error message for a conflicting mountRoute claimed by two pages.
local function mount_route_conflict_error(route, page_a, page_b)
    return string.format(
        '[views] mount route conflict: pages "%s" and "%s" both claim "%s".'
        .. ' Mount routes must be unique across all registered view.page entries.'
        .. ' Remove mountRoute from one of the pages, pick a different path,'
        .. ' or override in the top-level app by re-declaring the page id with a different mountRoute.',
        tostring(page_a), tostring(page_b), tostring(route)
    )
end

-- Validate all mountRoute fields in a page list.
-- Returns (routes_map, issues_list).
-- routes_map is a map from mountRoute → page_id (only populated for valid, non-conflicting entries).
-- issues_list is an array of error message strings.
--
-- Nil / missing mountRoute is silently skipped (pages without the field are fine).
-- Any non-nil, non-string value (number, boolean, table) is treated as a syntax
-- error — we refuse to silently swallow `mountRoute: false` or `mountRoute: 42`
-- because that would hide typos in the YAML.
function pages.validate_mount_routes(all_pages)
    local routes_map = {}
    local issues = {}
    local seen = {}  -- route → page_id (first-seen)

    if type(all_pages) ~= "table" then
        return routes_map, issues
    end

    for _, page in ipairs(all_pages) do
        local mr = page.mount_route
        if mr ~= nil and mr ~= "" then
            if type(mr) ~= "string" or not validate_mount_route_syntax(mr) then
                table.insert(issues, mount_route_syntax_error(page.id, mr))
            else
                local page_id = page.id
                if type(page_id) ~= "string" or page_id == "" then
                    -- Defensive: a page entry without a valid id would otherwise
                    -- collide with other id-less entries on the first dup check.
                    table.insert(issues, string.format(
                        '[views] page with mountRoute "%s" is missing a valid id.',
                        tostring(mr)
                    ))
                else
                    local previous = seen[mr]
                    if previous and previous ~= page_id then
                        table.insert(issues, mount_route_conflict_error(mr, page_id, previous))
                    else
                        seen[mr] = page_id
                        routes_map[mr] = page_id
                    end
                end
            end
        end
    end

    return routes_map, issues
end

-- Find mount routes across all pages.
-- Returns (routes_map, error_string).
-- On validation failure, routes_map is nil and error_string is a newline-joined
-- list of every issue found (syntax errors AND conflicts).
function pages.find_mount_routes()
    local all_pages, err = pages.find_all()
    if err then
        return nil, err
    end
    if not all_pages or #all_pages == 0 then
        return {}
    end

    local routes_map, issues = pages.validate_mount_routes(all_pages)
    if #issues > 0 then
        return nil, table.concat(issues, "\n")
    end

    return routes_map
end

-- Check if the current actor can access a page
function pages.can_access(page)
    if not page.secure then
        return true
    end

    local actor = security.actor()
    local scope = security.scope()

    if not actor or not scope then
        return false
    end

    local resource_id = "page:" .. page.id
    return security.can("view", resource_id)
end

return pages
