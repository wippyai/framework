-- bundled_meta.lua
--
-- Fetches the bundled `wippy-meta.json` that consumer builds emit (via
-- `@wippy-fe/vite-plugin`'s wippyPagePlugin / wippyComponentPlugin) and
-- exposes it as a parsed Lua table.
--
-- The presence of wippy-meta.json next to the served entry point is the
-- MANDATORY contract between consumer builds and `wippy/views` ≥ 1.0.31.
-- When present, views serves the bundled meta as the metadata response
-- (single source of truth = the consumer's package.json `wippy` block,
-- with all `file://` references resolved at build time).
--
-- When absent, callers should fall back to YAML-synthesis (deprecated;
-- exists only for migration of pre-1.0.31 consumers). See
-- `web_components.spec.md` § "Package metadata: source of truth".
--
-- Fetch transport: self-HTTP. We resolve `{page.base_url}wippy-meta.json`
-- and GET it against `PUBLIC_API_URL`. This is the cleanest path that
-- doesn't require either (a) reaching into the consumer's static dir from
-- Lua (would need fs-level access we don't have), or (b) baking the meta
-- into the registry entry at YAML-load time (would require touching the
-- registry loader). Self-HTTP adds one round-trip per metadata request,
-- which is acceptable for the cardinality of the views API (typically
-- cached at the consumer side anyway).

local json = require("json")
local http_client = require("http_client")
local store = require("store")
local page_registry = require("page_registry")
local component_registry = require("component_registry")

local M = {}

-- Default deadline for the self-fetch. Tight on purpose — if the consumer's
-- own static dir is slow to serve, something else is already broken.
local DEFAULT_TIMEOUT_SEC = 2

-- ID of the shared store.memory entry declared in _index.yaml. The store is
-- process-wide (not per-handler-worker), so the dedup survives across the
-- short-lived Lua worker processes that handle each request.
local WARN_STORE_ID = "wippy.views:bundled_meta_warn"

local function log_missing_once(entry_id: string?, kind: string, url: string)
    local key = tostring(entry_id or url)

    -- Try to claim the warning slot in the shared store. If the key already
    -- exists, another worker (or an earlier call on this worker) has already
    -- emitted the warning for this entry — silently skip.
    local s, store_err = store.get(WARN_STORE_ID)
    if store_err or not s then
        -- Store unavailable (shouldn't happen with the registry binding in
        -- _index.yaml). Fail open: log once-per-request rather than spam.
        -- The dedup is best-effort, not a correctness guarantee.
        s = nil
    else
        local existing = s:get(key)
        if existing then
            s:release()
            return
        end
        s:set(key, true)
        s:release()
    end

    print(string.format(
        "[wippy.views] %s '%s' has no wippy-meta.json at %s — falling back "
        .. "to YAML synthesis. Adopt @wippy-fe/vite-plugin "
        .. "(wippyPagePlugin / wippyComponentPlugin) so the consumer's "
        .. "package.json `wippy` block is the canonical source. "
        .. "See web_components.spec.md \"Package metadata: source of truth\".",
        kind, key, url
    ))
end

-- Internal: try fetching wippy-meta.json for a resolved entity.
-- `base_url` MUST be an absolute URL with trailing slash (as produced by
-- `page_registry.resolve_base_url` / `component_registry.resolve_base_url`).
-- Returns (table | nil, error_string | nil).
--
-- Treats 404 as "no bundled meta" (returns nil, nil) so callers can cleanly
-- fall back. Other status codes / network errors propagate as error strings.
local function fetch(base_url)
    if type(base_url) ~= "string" or base_url == "" then
        return nil, nil
    end

    -- Ensure trailing slash for clean concatenation
    local url = base_url
    if not url:match("/$") then
        url = url .. "/"
    end
    url = url .. "wippy-meta.json"

    local response, err = http_client.get(url, {
        timeout = DEFAULT_TIMEOUT_SEC,
        headers = { ["Accept"] = "application/json" },
    })

    if err or not response then
        -- Network-level failure: not a "missing meta", a real error.
        return nil, "wippy-meta fetch failed: " .. tostring(err or "no response")
    end

    if response.status_code == 404 then
        -- Bundle has no wippy-meta.json — this is the legacy/migration path.
        return nil, nil
    end

    if response.status_code < 200 or response.status_code >= 300 then
        return nil, "wippy-meta fetch returned " .. tostring(response.status_code) .. " for " .. url
    end

    local body = response.body or ""
    if body == "" then
        return nil, "wippy-meta fetch returned empty body for " .. url
    end

    local parsed, decode_err = json.decode(body)
    if decode_err then
        return nil, "wippy-meta parse error for " .. url .. ": " .. tostring(decode_err)
    end

    if type(parsed) ~= "table" then
        return nil, "wippy-meta is not a JSON object for " .. url
    end

    return parsed, nil
end

-- Fetch bundled meta for a page (view.page or view.component) resolved via
-- page_registry. Returns (meta | nil, error | nil). Nil + nil means "no
-- bundle present — caller should fall back to YAML-synthesis". A one-time
-- per-worker warning is logged on the first miss for a given page id so
-- the synthesis fallback never goes silent.
function M.fetch_for_page(page)
    if not page then
        return nil, "page is required"
    end
    local base_url = page_registry.resolve_base_url(page)
    local meta, err = fetch(base_url)
    if not meta and not err then
        local id = type(page.id) == "string" and (page.id :: string) or nil
        log_missing_once(id, "page", (base_url or "") .. "wippy-meta.json")
    end
    return meta, err
end

-- Fetch bundled meta for a component resolved via component_registry.
-- Same return contract as fetch_for_page.
function M.fetch_for_component(component)
    if not component then
        return nil, "component is required"
    end
    local base_url = component_registry.resolve_base_url(component)
    local meta, err = fetch(base_url)
    if not meta and not err then
        local id = type(component.id) == "string" and (component.id :: string) or nil
        log_missing_once(id, "component", (base_url or "") .. "wippy-meta.json")
    end
    return meta, err
end

-- Local deep-merge: overlay wins on conflicts, recursive on nested tables.
local function deep_merge(base: any, overlay: any): any
    if type(overlay) ~= "table" then return overlay end
    if type(base) ~= "table" then return overlay end
    local result: {[string]: any} = {}
    for k, v in pairs(base :: {[string]: any}) do result[k] = v end
    for k, v in pairs(overlay :: {[string]: any}) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = deep_merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- Project a parsed bundled wippy-meta.json + registry page entry into the
-- wippy-component-1.0 spec response shape served by GET /pages/content/{id}.
--
-- **Priority is YAML-first.** YAML is the abstraction OVER FE code: the
-- wippy operator's registry entry ALWAYS wins on a field-by-field basis.
-- Bundled meta is the fallback source for fields YAML omits (which, for
-- well-migrated entries, is most of the wippy block — props, proxy
-- defaults, customization payload, etc.).
--
-- Resolution per field:
--   - `name`                        → YAML `meta.name` → bundled top-level `name` → entry id
--   - `title`                       → YAML `meta.title` → bundled `wippy.title` → bundled top-level `title` → ""
--   - `version`, `specification`    → bundled top-level → spec defaults (these are package metadata, not registry concerns)
--   - `baseUrl`                     → always computed from the registry entry (routing the consumer can't decide)
--   - `wippy.type`                  → "page" (always)
--   - `wippy.path`                  → YAML `meta.entry_point` → bundled `wippy.path`
--                                    (bundled is source-relative — "dist/app.html"
--                                    is the canonical FE-author POV. YAML adjusts
--                                    to the operator's served layout, e.g. when
--                                    vite's --outDir flattens away the dist/ prefix.)
--   - `wippy.proxy`                 → bundled `wippy.proxy` (whole block; YAML has no canonical proxy override field for the new model)
--   - `wippy.configOverrides`       → bundled `wippy.configOverrides` deep-merged with YAML `meta.config_overrides` on top (variant overlay)
--
-- Extra package.json fields (dependencies, scripts, devDependencies, etc.)
-- are EXCLUDED from the response — only the wippy-component-1.0 spec
-- fields make it to the wire.
function M.project_page_response(bundled_meta, page, base_url)
    local meta: any = bundled_meta or {}
    local w: any = meta.wippy or {}

    local response = {
        name = page.name or meta.name or page.id,
        version = meta.version or "1.0.0",
        specification = meta.specification or "wippy-component-1.0",
        title = page.title or w.title or meta.title or "",
        baseUrl = base_url,
        wippy = {
            type = "page",
            -- Final fallback to "index.html" matches the legacy synthesis
            -- shape so unmigrated entries (no wippy-meta.json, no YAML
            -- entry_point) keep their pre-0.4.32 wire response.
            path = page.entry_point or w.path or "index.html",
            proxy = w.proxy,
            configOverrides = w.configOverrides,
        },
    }

    -- Merge YAML's config_overrides over bundled meta's configOverrides.
    -- The variant overlay pattern (iframe-demo-themed). YAML keys MUST be
    -- camelCase (cssVariables, customCSS) to merge correctly.
    if page.config_overrides then
        local current = response.wippy.configOverrides or {}
        response.wippy.configOverrides = deep_merge(current, page.config_overrides)
    end

    return response
end

-- Project a parsed bundled wippy-meta.json + registry component entry into
-- the snake_case-at-top-level response shape served by /components/list and
-- /components/by-tag/{tag}.
--
-- **Priority is YAML-first.** YAML is the abstraction OVER FE code: the
-- wippy operator's registry entry ALWAYS wins. Bundled meta is the
-- fallback for fields YAML omits.
--
-- Resolution per field:
--   - `id`, `base_url`, `auto_register` → always from the registry (routing + deployment policy)
--   - `name`         → YAML `meta.name` → bundled top-level `name`
--   - `title`        → YAML `meta.title` → bundled `wippy.title` → bundled top-level `title`
--   - `description`  → YAML `meta.description` → bundled `wippy.description` → bundled top-level `description`
--                     (carried in the response so LLM/agent consumers can
--                     pick the right component by reading its description)
--   - `tag_name`     → YAML `meta.tag_name` → bundled `wippy.tagName`
--   - `entry_point`  → YAML `meta.entry_point` → bundled top-level `browser`
--                     (`browser` is source-relative — the FE-author POV.
--                     YAML adjusts to the served layout; that's its job.
--                     NOT `wippy.path` — that field is page-only per
--                     wippy-component-1.0 spec; `browser` is the
--                     canonical entry for ESM module / component packages.)
--   - `props`        → YAML `meta.props` → bundled `wippy.props`
--   - `events`       → YAML `meta.events` → bundled `wippy.events`
function M.project_component_response(bundled_meta, component, base_url)
    local meta: any = bundled_meta or {}
    local w: any = meta.wippy or {}

    return {
        id = type(component.id) == "string" and component.id or tostring(component.id),
        name = component.name or meta.name or "",
        title = component.title or w.title or meta.title or "",
        description = component.description or w.description or meta.description,
        tag_name = component.tag_name or w.tagName,
        base_url = base_url,
        -- For components, the spec field is top-level `browser` (ESM module
        -- entry). `wippy.path` is reserved for view.page (HTML entry).
        -- Final fallback to "index.js" matches the legacy component
        -- response shape so unmigrated entries keep their pre-0.4.32 wire.
        entry_point = component.entry_point or meta.browser or "index.js",
        auto_register = component.auto_register == true,
        props = component.props or w.props,
        events = component.events or w.events,
    }
end

return M
