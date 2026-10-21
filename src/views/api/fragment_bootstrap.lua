-- Realm stub for fragment-mode views: the document of the hidden realm iframe
-- that `web-fragments` (reframed) creates for each fragment.
--
-- reframed starts streaming the page into the realm on the iframe's first
-- `load` event, so the import map must be registered while the stub parses:
--   * The Host map (`{fe_facade_url}/import-map.json`), the page's own map and
--     the page URL travel as one inert JSON payload in the stub.
--   * The configured map is the Host's accepted AppConfig `importMap`, which the
--     Host publishes as `window.__WIPPY_APP_CONFIG__` before it mounts any page.
--     Every realm is same-origin with its parent, so the stub reads it
--     synchronously from the nearest ancestor that carries it.
--   * The Web Host's `WippyImportMapBootstrap.register(page, host, config, base)`
--     validates the maps exactly as written, composes them (page < Host <
--     config, as the iframe engine does) and inserts one import map before any
--     module script exists in the realm. A `<base>` at the page URL exists only
--     during that call, so relative addresses resolve as in the iframe engine.
-- The proxy module loads only after the map is in place. A failure rejects
-- `window.__WIPPY_IMPORT_MAP_READY__` and loads no proxy. Host 1.0.66 waits for
-- that promise before it streams the page, so the page does not run, as the
-- iframe engine refuses the same maps. Hosts without `import-map-bootstrap.js`
-- get a static Host map.
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
-- `<!--`), and no U+2028/U+2029. Raises when the value cannot be encoded.
local function inline_json(value)
    local encoded, err = json.encode(value)
    if type(encoded) ~= "string" then
        error("cannot encode fragment stub JSON: " .. tostring(err), 0)
    end
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
  var hasOwn = Object.prototype.hasOwnProperty;
  var physicalParent = null;
  try { physicalParent = physicalWindow.parent !== physicalWindow ? physicalWindow.parent : null; } catch (_) { physicalParent = null; }
  function report(message, error) {
    try { physicalWindow.console.error(message, error); } catch (_) {}
  }
  function appendPhysicalFailure(message) {
    try {
      var target = physicalDocument.body || physicalDocument.documentElement;
      var alert = physicalCreateElement("p");
      alert.setAttribute("role", "alert");
      alert.textContent = message;
      target.appendChild(alert);
    } catch (renderError) {
      report("Could not render fragment initialization failure", renderError);
    }
  }
  function readConfiguredImportMap() {
    var current = physicalParent;
    var sawConfig = false;
    for (var depth = 0; current && depth < 32; depth++) {
      var config;
      try { config = current.__WIPPY_APP_CONFIG__; } catch (_) { break; }
      if (config && typeof config === "object") {
        sawConfig = true;
        if (hasOwn.call(config, "importMap")) return { found: true, map: config.importMap };
      }
      var next;
      try { next = current.parent; } catch (_) { break; }
      if (!next || next === current) break;
      current = next;
    }
    return { found: sawConfig, map: undefined };
  }
  // The iframe engine gives the page a <base href> at its HTML directory, so the
  // browser resolves relative addresses in all three maps against it. A realm's
  // own URL is the gateway route, so the same <base> exists only while
  // register() inserts the map: the browser resolves the addresses then, and
  // the realm keeps its own URL afterwards. register() resolves keys and scope
  // URLs against the same base and validates the maps exactly as written.
  // The proxy's own imports resolve through the map, so it loads only after the
  // map is registered. A script inserted before `load` still delays the realm's
  // `load` event, which web-fragments waits for before it streams the page.
  function loadProxy(url) {
    var script = physicalCreateElement("script");
    script.setAttribute("type", "module");
    script.setAttribute("src", url);
    (physicalDocument.head || physicalDocument.documentElement).appendChild(script);
  }
  function registerAtPageBase(bootstrap, pageMap, hostMap, configuredMap, pageBase) {
    var head = physicalDocument.head || physicalDocument.documentElement;
    var base = physicalCreateElement("base");
    base.setAttribute("href", pageBase);
    head.insertBefore(base, head.firstChild);
    try {
      bootstrap.register(pageMap, hostMap, configuredMap, pageBase);
    } finally {
      head.removeChild(base);
    }
  }
  try {
    var element = physicalGetElementById("wippy-fragment-bootstrap");
    var payload = JSON.parse(element && element.textContent || "{}");
    var hostMap = payload.hostMap || { imports: {} };
    var bootstrap = physicalWindow.WippyImportMapBootstrap;
    if (!bootstrap || typeof bootstrap.register !== "function") {
      // The helper did not load (for example a network failure). Keep the page
      // usable with the Host map alone, as on Hosts without the helper.
      report("Fragment import map: the Web Host import-map bootstrap is unavailable, so only the Host import map is applied.");
      var fallback = physicalCreateElement("script");
      fallback.setAttribute("type", "importmap");
      fallback.textContent = JSON.stringify(hostMap);
      (physicalDocument.head || physicalDocument.documentElement).appendChild(fallback);
      loadProxy(payload.proxyUrl);
      return;
    }
    var pageMap;
    if (typeof payload.pageMapText === "string") {
      try { pageMap = JSON.parse(payload.pageMapText); } catch (parseError) { throw new TypeError("Failed to parse page import map: " + String(parseError)); }
    }
    var pageBase = typeof payload.pageBase === "string" && payload.pageBase !== "" ? payload.pageBase : physicalBase;
    var configured = readConfiguredImportMap();
    if (!configured.found) report("Fragment import map: no Wippy Host configuration is readable from this realm, so the configured import map is not applied.");
    registerAtPageBase(bootstrap, pageMap, hostMap, configured.map, pageBase);
    loadProxy(payload.proxyUrl);
  } catch (error) {
    report("Fragment initialization failed", error);
    appendPhysicalFailure("This view could not be initialized. " + String(error && error.message || error));
    var failed = Promise.reject(error);
    failed.catch(function () {});
    physicalWindow.__WIPPY_IMPORT_MAP_READY__ = failed;
  }
})();
]]

local function attr_url(url)
    return replace_all(replace_all(url, "&", "&amp;"), '"', "&quot;")
end

--- Build the realm stub. Raises when a value cannot be encoded as JSON.
--- options.bootstrap: the Host serves `@wippy-fe/import-map-bootstrap.js`.
--- options.page_map: raw text of the page's first import map, or nil.
--- options.page_base: the URL of the page's HTML directory, which relative
--- import-map addresses resolve against.
local function build_stub(fbase, imports, options)
    options = options or {}
    local host_map = inline_json({ imports = imports or {} })
    local loading = '<script src="' .. attr_url(fbase .. "/@wippy-fe/loading.js") .. '"></script>'
    local proxy_url = fbase .. "/@wippy-fe/proxy-fragment.js"
    local head = '<!doctype html><title>Web Fragments: reframed</title>'
        .. '<script>window.__WIPPY_FRAGMENT_MODE__ = true;</script>'
    if not options.bootstrap then
        return head
            .. '<script type="importmap">' .. host_map .. '</script>'
            .. loading
            .. '<script type="module" src="' .. attr_url(proxy_url) .. '"></script>'
    end
    -- The page map stays raw text, so a malformed map gets the same parse error
    -- as in the iframe engine. Absent fields are left out. The register script
    -- loads the proxy from proxyUrl once the map is registered.
    local payload = inline_json({
        hostMap = { imports = imports or {} },
        pageMapText = options.page_map,
        pageBase = options.page_base,
        proxyUrl = proxy_url,
    })
    return head
        .. '<script type="application/json" id="wippy-fragment-bootstrap">' .. payload .. '</script>'
        .. loading
        .. '<script src="' .. attr_url(fbase .. "/@wippy-fe/import-map-bootstrap.js") .. '"></script>'
        .. '<script>' .. REGISTER_SCRIPT .. '</script>'
end

local function respond_text(res, status, message)
    res:set_header("Cache-Control", "no-store")
    res:set_content_type("text/plain")
    res:set_status(status)
    res:write(message)
end

--- Serve the realm stub. Returns true when a stub was written.
local function respond_iframe(res, fbase, imports, options)
    if not has_host_imports(imports) then
        respond_text(res, 503, "Web Host import map is unavailable")
        return false
    end
    local ok, stub = pcall(build_stub, fbase, imports, options)
    if not ok then
        respond_text(res, 500, "Fragment stub could not be built")
        return false
    end
    res:set_header("Vary", "sec-fetch-dest")
    -- Private: the stub carries the page's import map and is served only after
    -- the page access check.
    res:set_header("Cache-Control", "private, max-age=60")
    res:set_content_type("text/html")
    res:set_status(200)
    res:write(stub)
    return true
end

return {
    has_host_imports = has_host_imports,
    inline_json = inline_json,
    build_stub = build_stub,
    respond_iframe = respond_iframe,
}
