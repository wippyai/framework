-- Realm stub for fragment-mode views: the document of the hidden realm iframe
-- that `web-fragments` (reframed) creates for each fragment.
--
-- reframed starts streaming the page into the realm on the iframe's first
-- `load` event, so the import map must be registered while the stub parses:
--   * The Host map (`{fe_facade_url}/import-map.json`) and the page's own map
--     travel as inert JSON in the stub.
--   * The configured map is the Host's accepted AppConfig `importMap`, which the
--     Host publishes as `window.__WIPPY_APP_CONFIG__` before it mounts any page.
--     Every realm is same-origin with its parent, so the stub reads it
--     synchronously from the nearest ancestor that carries it.
--   * The Web Host's `WippyImportMapBootstrap.register(page, host, config)`
--     composes them (page < Host < config, as the iframe engine does) and
--     inserts one import map before any module script exists in the realm.
-- Hosts without `import-map-bootstrap.js` get the previous static Host map.
local json = require("json")

local function has_host_imports(imports)
    return type(imports) == "table" and next(imports) ~= nil
end

-- Literal (non-pattern) replacement of every occurrence of `from` in `text`.
local function replace_all(text, from, to)
    local out = {}
    local pos = 1
    while true do
        local s = text:find(from, pos, true)
        if not s then
            break
        end
        table.insert(out, text:sub(pos, s - 1))
        table.insert(out, to)
        pos = s + #from
    end
    table.insert(out, text:sub(pos))
    return table.concat(out)
end

-- JSON that is safe inside a <script> element: no `<` (so no `</script>` or
-- `<!--`), and no U+2028/U+2029.
local function inline_json(value)
    local encoded = json.encode(value) or "null"
    encoded = replace_all(encoded, "<", "\\u003c")
    encoded = replace_all(encoded, "\226\128\168", "\\u2028")
    encoded = replace_all(encoded, "\226\128\169", "\\u2029")
    return encoded
end

local REGISTER_SCRIPT = [[
(function () {
  var physicalWindow = window;
  var physicalDocument = window.document;
  var physicalBase = physicalDocument.baseURI || window.location.href;
  var physicalGetElementById = physicalDocument.getElementById.bind(physicalDocument);
  var physicalCreateElement = physicalDocument.createElement.bind(physicalDocument);
  var physicalParent = null;
  try { physicalParent = physicalWindow.parent !== physicalWindow ? physicalWindow.parent : null; } catch (_) { physicalParent = null; }
  function appendPhysicalFailure(message) {
    try {
      var target = physicalDocument.body || physicalDocument.documentElement;
      var alert = physicalCreateElement("p");
      alert.setAttribute("role", "alert");
      alert.textContent = message;
      target.appendChild(alert);
    } catch (renderError) {
      try { physicalWindow.console.error("Could not render fragment initialization failure", renderError); } catch (_) {}
    }
  }
  function resolveAddresses(addresses, base) {
    if (!addresses || typeof addresses !== "object" || Array.isArray(addresses)) return addresses;
    var out = Object.create(null);
    for (var key in addresses) {
      if (!Object.prototype.hasOwnProperty.call(addresses, key)) continue;
      var value = addresses[key];
      if (typeof value === "string" && (value.charAt(0) === "/" || value.slice(0, 2) === "./" || value.slice(0, 3) === "../")) {
        try { value = new URL(value, base).href; } catch (_) {}
      }
      out[key] = value;
    }
    return out;
  }
  // The iframe engine resolves the page map's relative addresses against the
  // page's <base href>. The realm's own URL is the gateway route, so resolve
  // them against the page URL here. Invalid shapes pass through to register().
  function resolvePageMap(map, base) {
    if (!map || typeof map !== "object" || Array.isArray(map)) return map;
    var out = Object.create(null);
    for (var key in map) if (Object.prototype.hasOwnProperty.call(map, key)) out[key] = map[key];
    if (Object.prototype.hasOwnProperty.call(out, "imports")) out.imports = resolveAddresses(out.imports, base);
    if (out.scopes && typeof out.scopes === "object" && !Array.isArray(out.scopes)) {
      var scopes = Object.create(null);
      for (var scope in out.scopes) if (Object.prototype.hasOwnProperty.call(out.scopes, scope)) scopes[scope] = resolveAddresses(out.scopes[scope], base);
      out.scopes = scopes;
    }
    return out;
  }
  function readConfiguredImportMap() {
    var current = physicalParent;
    var sawConfig = false;
    for (var depth = 0; current && depth < 32; depth++) {
      var config;
      try { config = current.__WIPPY_APP_CONFIG__; } catch (_) { break; }
      if (config && typeof config === "object") {
        sawConfig = true;
        if (Object.prototype.hasOwnProperty.call(config, "importMap")) return { found: true, map: config.importMap };
      }
      var next;
      try { next = current.parent; } catch (_) { break; }
      if (!next || next === current) break;
      current = next;
    }
    return { found: sawConfig, map: undefined };
  }
  try {
    var bootstrap = physicalWindow.WippyImportMapBootstrap;
    if (!bootstrap || typeof bootstrap.register !== "function") throw new Error("Web Host import-map bootstrap is unavailable");
    var hostMap = JSON.parse(physicalGetElementById("wippy-host-import-map").textContent || "{}");
    var pageText = JSON.parse(physicalGetElementById("wippy-page-import-map").textContent || "null");
    var pageMap;
    if (typeof pageText === "string") {
      try { pageMap = JSON.parse(pageText); } catch (parseError) { throw new TypeError("Failed to parse page import map: " + String(parseError)); }
    }
    var pageBase = JSON.parse(physicalGetElementById("wippy-page-base").textContent || "null");
    if (typeof pageBase !== "string" || pageBase === "") pageBase = physicalBase;
    var configured = readConfiguredImportMap();
    if (!configured.found) physicalWindow.console.error("Fragment import map: no Wippy Host configuration is readable from this realm, so the configured import map is not applied.");
    bootstrap.register(resolvePageMap(pageMap, pageBase), hostMap, configured.map, pageBase);
  } catch (error) {
    try { physicalWindow.console.error("Fragment initialization failed", error); } catch (_) {}
    appendPhysicalFailure("This view could not be initialized. " + String(error && error.message || error));
  }
})();
]]

local function attr_url(url)
    return replace_all(replace_all(url, "&", "&amp;"), '"', "&quot;")
end

--- Build the realm stub.
--- options.bootstrap: the Host serves `@wippy-fe/import-map-bootstrap.js`.
--- options.page_map: raw text of the page's first import map, or nil.
--- options.page_base: the page's base URL, which relative page-map entries
--- resolve against.
local function build_stub(fbase, imports, options)
    options = options or {}
    local host_map = inline_json({ imports = imports or {} })
    local loading = '<script src="' .. attr_url(fbase .. "/@wippy-fe/loading.js") .. '"></script>'
    local proxy = '<script type="module" src="' .. attr_url(fbase .. "/@wippy-fe/proxy-fragment.js") .. '"></script>'
    local head = '<!doctype html><title>Web Fragments: reframed</title>'
        .. '<script>window.__WIPPY_FRAGMENT_MODE__ = true;</script>'
    if not options.bootstrap then
        return head
            .. '<script type="importmap">' .. host_map .. '</script>'
            .. loading
            .. proxy
    end
    local page_map = options.page_map ~= nil and inline_json(options.page_map) or "null"
    local page_base = options.page_base ~= nil and inline_json(options.page_base) or "null"
    return head
        .. '<script type="application/json" id="wippy-host-import-map">' .. host_map .. '</script>'
        .. '<script type="application/json" id="wippy-page-import-map">' .. page_map .. '</script>'
        .. '<script type="application/json" id="wippy-page-base">' .. page_base .. '</script>'
        .. loading
        .. '<script src="' .. attr_url(fbase .. "/@wippy-fe/import-map-bootstrap.js") .. '"></script>'
        .. '<script>' .. REGISTER_SCRIPT .. '</script>'
        .. proxy
end

local function respond_iframe(res, fbase, imports, options)
    if not has_host_imports(imports) then
        res:set_header("Cache-Control", "no-store")
        res:set_content_type("text/plain")
        res:set_status(503)
        res:write("Web Host import map is unavailable")
        return false
    end
    res:set_header("Vary", "sec-fetch-dest")
    -- Private: the stub now carries the page's import map and is served only
    -- after the page access check.
    res:set_header("Cache-Control", "private, max-age=60")
    res:set_content_type("text/html")
    res:set_status(200)
    res:write(build_stub(fbase, imports, options))
    return true
end

return {
    has_host_imports = has_host_imports,
    inline_json = inline_json,
    build_stub = build_stub,
    respond_iframe = respond_iframe,
}
