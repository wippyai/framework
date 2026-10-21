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
--
-- The self-fetch is also the weak point: `PUBLIC_API_URL` is the address
-- browsers use, and a server behind a proxy, WAF, SSO edge or port mapping
-- often cannot reach it. A failed fetch still renders the page (from its
-- YAML entry), only without its package settings, so every failure is
-- logged as an error with the fix and returned to the caller as a
-- diagnostic the Host can show in the browser console.

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

-- Log a failed fetch once per entry and error (shared store, so handler-pool
-- workers do not repeat it). Returns the operator message.
local function log_fetch_failure_once(kind: string, entry_id: string?, url: string, err: string): string
    local message = M.describe_fetch_failure(kind, entry_id, url, err)
    local key = "error:" .. tostring(entry_id or url) .. ":" .. err

    local s, store_err = store.get(WARN_STORE_ID)
    if not store_err and s then
        local existing = s:get(key)
        if not existing then
            s:set(key, true)
        end
        s:release()
        if existing then
            return message
        end
    end

    -- Create the logger here, not at module load: a named logger created when
    -- the library loads is silently dropped when a function handler (such as
    -- the /pages/content endpoint) calls it later (seen on runtime 0.3.47a).
    require("logger"):named("wippy.views"):error(message, { kind = kind, id = entry_id, url = url, error = err })
    return message
end

-- The operator message for a wippy-meta.json that could not be read: what
-- failed, what the page loses, and how to fix it.
function M.describe_fetch_failure(kind: string, entry_id: string?, url: string, err: string): string
    return string.format(
        "wippy/views could not read wippy-meta.json for %s '%s' from %s (%s). "
        .. "The %s is served from its registry entry instead, without the package.json "
        .. "settings in that file: configOverrides (theme variables and custom CSS), "
        .. "proxy injections and renderEngine. This server fetches the file through "
        .. "PUBLIC_API_URL. Set PUBLIC_API_URL to an absolute http(s) URL that both "
        .. "browsers and this server can reach, and check that a request from the "
        .. "server to %s returns HTTP 200.",
        kind, tostring(entry_id or "?"), url, err, kind, url
    )
end

-- Internal: try fetching wippy-meta.json for a resolved entity.
-- `base_url` MUST be an absolute URL with trailing slash (as produced by
-- `page_registry.resolve_base_url` / `component_registry.resolve_base_url`).
-- Returns (table | nil, error_string | nil, url).
--
-- Treats 404 as "no bundled meta" (returns nil, nil) so callers can cleanly
-- fall back. Other status codes / network errors propagate as error strings.
local function fetch(base_url)
    if type(base_url) ~= "string" or base_url == "" then
        return nil, nil, nil
    end

    -- Ensure trailing slash for clean concatenation
    local url = base_url
    if not url:match("/$") then
        url = url .. "/"
    end
    url = url .. "wippy-meta.json"

    -- A relative URL means PUBLIC_API_URL is empty or not an http(s) URL. The
    -- HTTP client cannot fetch it ("unsupported protocol scheme"), so say why.
    if not url:match("^https?://") then
        return nil, "the URL is not absolute, so PUBLIC_API_URL is empty or not an http(s) URL", url
    end

    local response, err = http_client.get(url, {
        timeout = DEFAULT_TIMEOUT_SEC,
        headers = { ["Accept"] = "application/json" },
    })

    if err or not response then
        -- Network-level failure: not a "missing meta", a real error.
        return nil, "fetch failed: " .. tostring(err or "no response"), url
    end

    if response.status_code == 404 then
        -- Bundle has no wippy-meta.json — this is the legacy/migration path.
        return nil, nil, url
    end

    if response.status_code < 200 or response.status_code >= 300 then
        return nil, "HTTP " .. tostring(response.status_code), url
    end

    local body = response.body or ""
    if body == "" then
        return nil, "empty response body", url
    end

    local parsed, decode_err = json.decode(body)
    if decode_err then
        return nil, "response is not JSON: " .. tostring(decode_err), url
    end

    if type(parsed) ~= "table" then
        return nil, "response is not a JSON object", url
    end

    return parsed, nil, url
end

M._fetch = fetch

-- Fetch bundled meta for a page (view.page or view.component) resolved via
-- page_registry. Returns (meta | nil, error | nil). Nil + nil means "no
-- bundle present — caller should fall back to YAML-synthesis". A one-time
-- per-worker warning is logged on the first miss for a given page id so
-- the synthesis fallback never goes silent. On a failed fetch the error is
-- the full operator message (logged once as an error).
function M.fetch_for_page(page)
    if not page then
        return nil, "page is required"
    end
    local base_url = page_registry.resolve_base_url(page)
    local meta, err, url = fetch(base_url)
    local id = type(page.id) == "string" and (page.id :: string) or nil
    if err then
        return nil, log_fetch_failure_once("page", id, url or "", err)
    end
    if not meta then
        log_missing_once(id, "page", (base_url or "") .. "wippy-meta.json")
    end
    return meta, nil
end

-- Fetch bundled meta for a component resolved via component_registry.
-- Same return contract as fetch_for_page.
function M.fetch_for_component(component)
    if not component then
        return nil, "component is required"
    end
    local base_url = component_registry.resolve_base_url(component)
    local meta, err, url = fetch(base_url)
    local id = type(component.id) == "string" and (component.id :: string) or nil
    if err then
        return nil, log_fetch_failure_once("component", id, url or "", err)
    end
    if not meta then
        log_missing_once(id, "component", (base_url or "") .. "wippy-meta.json")
    end
    return meta, nil
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
--   - `wippy.proxy`                 → bundled `wippy.proxy` deep-merged with YAML `meta.proxy` on top (variant overlay; YAML wins per nested key)
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
            -- EE2-2313: per-page render engine (auto|iframe|fragment). Bundled
            -- wippy.renderEngine here; operator override applied below.
            renderEngine = w.renderEngine,
        },
    }

    -- Merge YAML's config_overrides over bundled meta's configOverrides.
    -- The variant overlay pattern (iframe-demo-themed). YAML keys MUST be
    -- camelCase (cssVariables, customCSS) to merge correctly.
    if page.config_overrides then
        local current = response.wippy.configOverrides or {}
        response.wippy.configOverrides = deep_merge(current, page.config_overrides)
    end

    -- Merge YAML's `meta.proxy` over bundled meta's wippy.proxy. Same overlay
    -- as config_overrides: YAML wins per nested key, untouched bundle keys
    -- survive. The YAML payload MUST be camelCase (enabled,
    -- injections.css.customCss) to merge with the camelCase bundle proxy.
    if page.proxy then
        local current = response.wippy.proxy or {}
        response.wippy.proxy = deep_merge(current, page.proxy)
    end

    -- EE2-2313: scalar (NOT deep-merge) YAML operator override for the render
    -- engine. meta.render_engine → page.render_engine wins over the bundle.
    if page.render_engine ~= nil then
        response.wippy.renderEngine = page.render_engine
    end

    -- The FE rejects a page descriptor with no wippy.proxy
    -- (isWippyPackageWebPage). A bundle that omits a proxy block, with no YAML
    -- override, lands here — emit a minimal truthy proxy. The FE owns the
    -- injection defaults (every injection ON when absent).
    if not response.wippy.proxy then
        response.wippy.proxy = { enabled = true }
    end

    return response
end

-- Project a parsed bundled wippy-meta.json + registry component entry into
-- the camelCase wippy-component-1.0 ESM descriptor served by /components/list
-- and /components/by-tag/{tag}. The FE consumes this shape DIRECTLY (no
-- re-assembly) — it is a valid PackageJsonESM, same family as the page
-- descriptor from project_page_response.
--
-- **Priority is YAML-first.** YAML is the abstraction OVER FE code: the
-- wippy operator's registry entry ALWAYS wins. Bundled meta is the
-- fallback for fields YAML omits.
--
-- Resolution per field:
--   - `id`, `baseUrl`, `wippy.autoRegister` → always from the registry (routing + deployment policy)
--   - `name`               → YAML `meta.name` → bundled top-level `name`
--   - `version`, `specification` → bundled top-level → spec defaults
--   - `title`              → YAML `meta.title` → bundled `wippy.title` → bundled top-level `title`
--   - `description`        → YAML `meta.description` → bundled `wippy.description` → bundled top-level `description`
--   - `wippy.tagName`      → YAML `meta.tag_name` → bundled `wippy.tagName`
--   - `browser`            → YAML `meta.entry_point` → bundled top-level `browser`
--                            (`browser` is the spec entry for ESM/component
--                            packages — NOT `wippy.path`, which is page-only.
--                            Source-relative FE POV; YAML adjusts to the
--                            operator's served layout.)
--   - `wippy.props`        → YAML `meta.props` → bundled `wippy.props`
--   - `wippy.events`       → YAML `meta.events` → bundled `wippy.events`
--   - `wippy.autoRegister` → always registry `meta.auto_register` (deployment
--                            policy; the bundle's `wippy.autoRegister` is ignored).
function M.project_component_response(bundled_meta, component, base_url)
    local meta: any = bundled_meta or {}
    local w: any = meta.wippy or {}

    return {
        id = type(component.id) == "string" and component.id or tostring(component.id),
        name = component.name or meta.name or "",
        version = meta.version or "1.0.0",
        specification = meta.specification or "wippy-component-1.0",
        title = component.title or w.title or meta.title or "",
        description = component.description or w.description or meta.description,
        baseUrl = base_url,
        -- Spec entry field for components is top-level `browser` (ESM module
        -- entry). `wippy.path` is reserved for view.page (HTML entry). Final
        -- fallback to "index.js" matches the legacy component response shape.
        browser = component.entry_point or meta.browser or "index.js",
        wippy = {
            tagName = component.tag_name or w.tagName,
            type = w.type or "widget",
            props = component.props or w.props,
            events = component.events or w.events,
            autoRegister = component.auto_register == true,
        },
    }
end

return M
