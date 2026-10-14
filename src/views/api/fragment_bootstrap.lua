-- Pure response/template helpers for the fragment gateway iframe.
local json = require("json")

local function has_host_imports(imports)
    return type(imports) == "table" and next(imports) ~= nil
end

local function inline_json(value)
    local encoded = json.encode(value) or "{}"
    return encoded
        :gsub("<", "\\u003c")
        :gsub("\226\128\168", "\\u2028")
        :gsub("\226\128\169", "\\u2029")
end

local function build_stub(fbase, imports)
    local host_map = inline_json({ imports = imports or {} })
    local proxy_url = inline_json(fbase .. "/@wippy-fe/proxy-fragment.js")
    local host_version = fbase:match("/webcomponents%-1%.0%.(%d+)$")
    -- Versioned older Hosts keep their published map + proxy startup without a helper request.
    -- Unversioned custom/dev URLs are treated as 1.0.63+ and must serve this helper.
    local use_parent_bootstrap = not host_version or tonumber(host_version) >= 63
    if not use_parent_bootstrap then
        return '<!doctype html><title>Web Fragments: reframed</title>'
            .. '<script>window.__WIPPY_FRAGMENT_MODE__ = true;</script>'
            .. '<script type="importmap">' .. host_map .. '</script>'
            .. '<script src="' .. fbase .. '/@wippy-fe/loading.js"></script>'
            .. '<script type="module" src=' .. proxy_url .. '></script>'
    end
    return '<!doctype html><title>Web Fragments: reframed</title>'
        .. '<script>window.__WIPPY_FRAGMENT_MODE__ = true;</script>'
        .. '<script type="application/json" id="wippy-host-import-map">' .. host_map .. '</script>'
        .. '<script src="' .. fbase .. '/@wippy-fe/loading.js"></script>'
        .. '<script src="' .. fbase .. '/@wippy-fe/import-map-bootstrap.js"></script>'
        .. '<script>(function () {'
        .. ' const physicalWindow = window; const physicalDocument = window.document;'
        .. ' const physicalLocation = window.location; const physicalBase = physicalDocument.baseURI || physicalLocation.href;'
        .. ' const physicalRoot = physicalDocument.documentElement; const physicalBody = physicalDocument.body;'
        .. ' const physicalTarget = physicalBody || physicalRoot;'
        .. ' const physicalAppend = physicalTarget && typeof physicalTarget.appendChild === "function" ? physicalTarget.appendChild.bind(physicalTarget) : null;'
        .. ' const physicalCreateElement = physicalDocument.createElement.bind(physicalDocument);'
        .. ' const physicalGetElementById = physicalDocument.getElementById.bind(physicalDocument);'
        .. ' const appendPhysicalFailure = function (message) {'
        .. '  try { if (!physicalTarget || !physicalAppend) throw new Error("Physical document root is unavailable");'
        .. '   const alert = physicalCreateElement("p"); alert.setAttribute("role", "alert"); alert.textContent = message; physicalAppend(alert);'
        .. '  } catch (renderError) { try { physicalWindow.console.error("Could not render fragment initialization failure", renderError); } catch (_) {} }'
        .. ' };'
        .. ' physicalWindow.__WIPPY_IMPORT_MAP_READY__ = (async function () { try {'
        .. '  const bootstrap = physicalWindow.WippyImportMapBootstrap;'
        .. '  if (!bootstrap || typeof bootstrap.waitForConfig !== "function" || typeof bootstrap.register !== "function") throw new Error("Web Host import-map bootstrap is unavailable");'
        .. '  const hostMap = JSON.parse(physicalGetElementById("wippy-host-import-map").textContent || "{}");'
        .. '  const config = await bootstrap.waitForConfig({ waitForParent: true, waitForNestedInjection: true });'
        .. '  bootstrap.register(undefined, hostMap, config.importMap, physicalBase);'
        .. '  await import(' .. proxy_url .. ');'
        .. '  if (typeof physicalWindow.getWippyApi !== "function") throw new Error("Fragment proxy did not expose the Wippy API");'
        .. '  await physicalWindow.getWippyApi(); return config;'
        .. ' } catch (error) {'
        .. '  try { physicalWindow.console.error("Fragment initialization failed", error); } catch (_) {}'
        .. '  appendPhysicalFailure("This view could not be initialized. " + String(error && error.message || error));'
        .. '  throw error;'
        .. ' } })();'
        .. '})();</script>'
        .. '<script>window.__WIPPY_IMPORT_MAP_READY__.catch(function () {});</script>'
end

local function respond_iframe(res, fbase, imports)
    if not has_host_imports(imports) then
        res:set_header("Cache-Control", "no-store")
        res:set_content_type("text/plain")
        res:set_status(503)
        res:write("Web Host import map is unavailable")
        return false
    end
    res:set_header("Vary", "sec-fetch-dest")
    res:set_header("Cache-Control", "public, max-age=300")
    res:set_content_type("text/html")
    res:set_status(200)
    res:write(build_stub(fbase, imports))
    return true
end

return {
    has_host_imports = has_host_imports,
    build_stub = build_stub,
    respond_iframe = respond_iframe,
}
